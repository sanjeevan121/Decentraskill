// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Decentraskill {
    company[] public companies;
    user[] public employees;
    certificate[] public certifications;
    endorsment[] public endorsments;
    skill[] public skills;
    experience[] public experiences;

    mapping(string => address) public email_to_address;
    mapping(address => uint256) public address_to_id;
    mapping(address => bool) public is_company;

    struct company {
        uint256 id;
        string name;
        address wallet_address;
        uint256[] current_employees;
        uint256[] previous_employees;
        uint256[] requested_employees;
    }

    struct certificate {
        string url;
        string issue_date;
        string valid_till;
        string name;
        uint256 id;
        string issuer;
    }

    struct endorsment {
        uint256 endorser_id;
        string date;
        string comment;
    }

    struct experience {
        string starting_date;
        string ending_date;
        string role;
        bool currently_working;
        uint256 company_id;
        bool is_approved;
    }

    struct skill {
        string name;
        bool verified;
        uint256[] skill_certifications;
        uint256[] skill_endorsements;
    }

    struct user {
        uint256 id;
        uint256 company_id;
        string name;
        address wallet_address;
        bool is_employed;
        bool is_manager;
        uint256 num_skill;
        uint256[] user_skills;
        uint256[] user_work_experience;
    }

    constructor() {
        user storage dummy_user = employees.push();
        dummy_user.name = "dummy";
        dummy_user.wallet_address = msg.sender;
        dummy_user.id = 0;
        dummy_user.user_skills = new uint256[](0);
        dummy_user.user_work_experience = new uint256[](0);
    }

    function memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strcmp(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return memcmp(bytes(a), bytes(b));
    }

    function sign_up(
        string calldata email,
        string calldata name,
        string calldata acc_type
    ) public {
        require(email_to_address[email] == address(0));
        email_to_address[email] = msg.sender;

        if (strcmp(acc_type, "user")) {
            user storage new_user = employees.push();
            new_user.name = name;
            new_user.id = employees.length - 1;
            new_user.wallet_address = msg.sender;
            address_to_id[msg.sender] = new_user.id;
            new_user.user_skills = new uint256[](0);
            new_user.user_work_experience = new uint256[](0);
        } else {
            company storage new_company = companies.push();
            new_company.name = name;
            new_company.id = companies.length - 1;
            new_company.wallet_address = msg.sender;
            new_company.current_employees = new uint256[](0);
            new_company.previous_employees = new uint256[](0);
            address_to_id[msg.sender] = new_company.id;
            is_company[msg.sender] = true;
        }
    }

    function approve_manager(uint256 employee_id) public {
        require(is_company[msg.sender]);
        require(employees[employee_id].company_id == address_to_id[msg.sender]);
        require(!(employees[employee_id].is_manager));
        employees[employee_id].is_manager = true;
    }

    function login(string calldata email) public view returns (string memory) {
        require(msg.sender == email_to_address[email]);
        return (is_company[msg.sender]) ? "company" : "user";
    }

    function add_certification(
        string calldata url,
        string calldata issue_date,
        string calldata valid_till,
        string calldata name,
        string calldata issuer
    ) public {
        certificate storage new_certificate = certifications.push();
        new_certificate.url = url;
        new_certificate.issue_date = issue_date;
        new_certificate.valid_till = valid_till;
        new_certificate.name = name;
        new_certificate.id = certifications.length - 1;
        new_certificate.issuer = issuer;
    }

    function add_skill(uint256 userid, string calldata skill_name) public {
        skill storage new_skill = skills.push();
        employees[userid].user_skills.push(skills.length - 1);
        new_skill.name = skill_name;
        new_skill.verified = false;
        new_skill.skill_certifications = new uint256[](0);
        new_skill.skill_endorsements = new uint256[](0);
    }

    function endorse_skill(
        uint256 user_id,
        uint256 skill_id,
        string calldata endorsing_date,
        string calldata comment
    ) public {
        endorsment storage new_endorsemnt = endorsments.push();
        new_endorsemnt.endorser_id = address_to_id[msg.sender];
        new_endorsemnt.comment = comment;
        new_endorsemnt.date = endorsing_date;
        skills[skill_id].skill_endorsements.push(endorsments.length - 1);
        if (employees[address_to_id[msg.sender]].is_manager) {
            if (
                employees[address_to_id[msg.sender]].company_id ==
                employees[user_id].company_id
            ) {
                skills[skill_id].verified = true;
            }
        }
    }

    function add_experience(
        uint256 user_id,
        string calldata starting_date,
        string calldata ending_date,
        string calldata role,
        uint256 company_id
    ) public {
        experience storage new_experience = experiences.push();
        new_experience.company_id = company_id;
        new_experience.currently_working = false;
        new_experience.is_approved = false;
        new_experience.starting_date = starting_date;
        new_experience.ending_date = ending_date;
        new_experience.role = role;
        employees[user_id].user_work_experience.push(experiences.length - 1);
        companies[company_id].requested_employees.push(experiences.length - 1);
    }

    function approve_experience(uint256 exp_id, uint256 company_id) public {
        require(experiences[exp_id].company_id == company_id);
        require(
            (is_company[msg.sender] &&
                companies[address_to_id[msg.sender]].id == company_id) ||
                (employees[address_to_id[msg.sender]].is_manager &&
                    employees[address_to_id[msg.sender]].company_id ==
                    company_id)
        );
        uint256 i;
        experiences[exp_id].is_approved = true;
        for (i = 0; i < companies[company_id].requested_employees.length; i++) {
            if (companies[company_id].requested_employees[i] == exp_id) {
                companies[company_id].requested_employees[i] = 0;
                break;
            }
        }
        for (i = 0; i < companies[company_id].current_employees.length; i++) {
            if (companies[company_id].current_employees[i] == 0) {
                companies[company_id].requested_employees[i] = exp_id;
                break;
            }
        }
        if (i == companies[company_id].current_employees.length)
            companies[company_id].current_employees.push(exp_id);
    }

    function update_wallet_address(string calldata email, address new_address)
        public
    {
        require(email_to_address[email] == msg.sender);
        email_to_address[email] = new_address;
        address_to_id[msg.sender] = 0;
    }
}

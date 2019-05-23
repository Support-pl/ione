ione-ansible

## Admin side

### Playbooks

#### Create
Creates playbook(after form confirmed - writing to DB). Fields:
* Name - String(<128 sym.)
* Description - text, where you can write anything. For example describe playbook task by task.
* Body - playbook body written in YAML. Additional syntax rules:
    * Object must be Array of playbooks(begins with e.g. " - hosts:")
    * hosts must contain only "<%group%>", to be processes runned correctly
    * If playbook contains vars field, every variable must have default value written.
> You can check syntax by clicking on button "Check Syntax" while creating Playbook or calling method `check_syntax`

When you writting playbook from interface, next fields will be filled automatically:
* User ID and user Group ID will be used as Owner and Group of new playbook 
* Rights bytes 700(**rwx\-\-\-\-\-\-**)
* Create time

#### Update
By this action you can change data at playbook fields.
> **MANAGE** access-level required

#### Run
Will open [AnsiblePlaybookProcess.create](#label-Create)
> **USE** access-level required

#### Rename
You can edit Playbooks name by clicking on *edit-icon* near the playbooks name and entering new name in opened form.
> **MANAGE** access-level required

#### CHMOD
You can change Playbooks access rights using the table of checkboxes which you can see at Playbook show page.
Rights are separated by 3 levels:
* Use
* Manage
* Admin

And by 3 groups:
* Owner
* Group
* Others

#### CHOWN
You can change playbooks owner, by clicking on *edit-icon* near the playbooks owner name and choosing needed from dropdown list.
> **ADMIN** access-level required

#### CHGRP
You can change playbooks group, by clicking on *edit-icon* near the playbooks owner name and choosing needed from dropdown list.
> **ADMIN** access-level required

#### Delete
This action will delete Playbook from DB
> **ADMIN** access-level required

### Processes

#### Create
Creates Process instance and writes it to DB.
Process has the following fields:
* proc_id - Unical numeric identificator, key DB field
* install_id - SecureRandom UUID, uses as group
* playbook_id - Playbook ID, which is runned
* uid - User ID, who created process
* create_time - Time when Process was created
* start_time - Time when Process was runned
* end_time - TIme when Process was ended
* status - Process status(one from eight: PENDING - created, RUNNING - started and working, SUCCESS - ended successfully(no failed tasks and most tasks are ok), CHANGED - most of tasks are "changed", UNREACHABLE - most of tasks are "unreachable", that means that most of hosts were unreachable, FAILED - some tasks are failed, LOST - log file lost, DONE - process deleted)
* log - Ansible default log text
* hosts - VMs IDs and their IPs with ports list, where current playbook should be runned or where runned
* vars - variables which were given to run this playbook
* playbook_name - playbook name(saves to be used in UI)
* runnable - playbook body with inserted variables
* comment - comment attached to Process
* codes - ansible tasks codes (ok, unreachable, changed, failed)


#### Run
Runs playbook at given hosts

#### Удалить    | Delete
Sets Process status to **DONE**
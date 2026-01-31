def get_users_with_shell():
    """Get a list of all users on the system that have a specified shell."""
    shells = ["/bin/sh", "/bin/bash", "/bin/zsh", "/bin/csh"]
    users = []
    with open("/etc/passwd", "r") as passwd_file:
        for entry in passwd_file:
            if any(shell in entry for shell in shells):
                users.append(entry.split(":")[0])
    return users


def get_user_groups():
    """Make a dictionary of {user: [groups they're in]} for users with shells."""
    user_groups = {user: [] for user in get_users_with_shell()}
    with open("/etc/group", "r") as groups_file:
        for entry in groups_file:
            group_name = entry.split(":")[0]
            members = entry.strip().split(":")[-1].split(",")
            for user in user_groups:
                if user in members:
                    user_groups[user].append(group_name)
    return user_groups


def get_root_users():
    """Get a list of all users with administrative privileges."""
    user_groups = get_user_groups()
    admin_groups = ["root", "wheel", "admin"]
    admins = [
        user
        for user, groups in user_groups.items()
        if any(group in admin_groups for group in groups)
    ]
    return admins


print("Users that have a shell:")
print("\n".join(get_users_with_shell()))
print()
print("Root Users:")
print("\n".join(get_root_users()))

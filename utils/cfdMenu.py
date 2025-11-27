import sys
import os
import subprocess
from typing import Callable, Literal, Optional
import getpass
import tty
import termios
import pwd

MENU_PWD = os.path.dirname(os.path.abspath(__file__))


def get_unix_username() -> str:
    """
    Return the current UNIX username in a robust way.
    """
    try:
        # Preferred: getpass works in most interactive contexts
        return getpass.getuser()
    except Exception:
        try:
            # Fallback to pwd using effective UID
            return pwd.getpwuid(os.geteuid()).pw_name
        except Exception:
            # Final fallback to environment variables
            return os.environ.get('USER') or os.environ.get('USERNAME') or 'unknown'


# convenience constant
UNIX_USER = get_unix_username()


class KeyInput:
    """
    Handles reading a single keystroke from the user without 
    requiring them to press Enter. Works on Windows and Unix.
    """

    def __init__(self):
        self.impl = 'unix'
        self.tty = tty
        self.termios = termios

    def get_key(self):
        fd = sys.stdin.fileno()
        old_settings = self.termios.tcgetattr(fd)
        try:
            self.tty.setraw(sys.stdin.fileno())
            ch = sys.stdin.read(1)
            # Handle escape sequences for arrow keys
            if ch == '\x1b':
                ch += sys.stdin.read(2)
        finally:
            self.termios.tcsetattr(
                fd, self.termios.TCSADRAIN, old_settings)
        return ch


def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')


class OptionNode:
    """
    Tree node for menu options.
    """
    name: str
    parent: Optional["OptionNode"]
    children: list["OptionNode"]
    handler: Optional[Callable]

    def __init__(self, name, handler: Optional[Callable] = None):
        self.name = name
        self.parent = None
        self.children = []
        self.handler = handler

    def add_child(self, child_node):
        child_node.parent = self
        self.children.append(child_node)


def interactive_menu(node: OptionNode) -> Optional[OptionNode]:
    """
    Recursive interactive menu using the OptionNode tree.

    - Displays the children of `node`.
    - If a selected child has its own children, call recursively into it.
    - If a selected child is a leaf and has a `command`, run it.
    - Returns the selected leaf `OptionNode`, or None if the user quits/back's out
    """
    key_reader = KeyInput()
    selected_idx = 0

    # ANSI Colors
    RESET = '\033[0m'
    HIGHLIGHT = '\033[7m'

    while True:
        children = node.children
        # If there are no children, this is a leaf — nothing to show here
        if not children:
            return node

        clear_screen()
        print(f"=== {node.name} ===")
        instructions = "(Use UP/DOWN arrows to move, ENTER to select, 'q' to go back)"
        print(instructions)
        print("-" * 40)

        # If node has a parent, offer an explicit Back option as first entry
        menu_entries = list(children)
        if node.parent is not None:
            menu_entries = menu_entries

        for idx, option in enumerate(menu_entries):
            label = option.name
            if idx == selected_idx:
                print(f"{HIGHLIGHT} > {label} {RESET}")
            else:
                print(f"   {label}")

        # Wait for input
        key = key_reader.get_key()

        if key == '\x1b[A':  # Up Arrow
            selected_idx = (selected_idx - 1) % len(menu_entries)
        elif key == '\x1b[B':  # Down Arrow
            selected_idx = (selected_idx + 1) % len(menu_entries)
        elif key == '\r' or key == '\n':  # Enter Key
            selected = menu_entries[selected_idx]
            # If selected has children, recurse into it
            if selected.children:
                res = interactive_menu(selected)
                # If the recursive call returns None, that means the user backed out
                # so continue showing current menu. If it returns a node, bubble it up.
                if res is None:
                    continue
                return res

            # Leaf node: run handler if present, otherwise return it
            if selected.handler:
                clear_screen()
                try:
                    selected.handler()
                except Exception as e:
                    print(
                        f"Failed to run handler for: {selected.name}. Error: {e}")
            return selected
        elif key == 'q':  # Q to quit/back
            return None


def helyx_menu_setup():
    def run_pipeline(type: Literal["run", "check"]):
        name = input("Enter the name for the Helyx case: ")
        nodes = input("Enter the number of nodes to use: ")
        tasks_per_node = input("Enter the number of tasks per node: ")
        email_address = input("Enter your email address for notifications: ")

        if not nodes.isdigit() or not tasks_per_node.isdigit():
            print("Error: Number of nodes and tasks per node must be integers.")
            return

        script = MENU_PWD + "/pipelines/helyx/create_scripts.sh"
        total_tasks = str(int(nodes) * int(tasks_per_node))
        # Call the script directly (no shell) and raise on non-zero exit
        subprocess.run([
            "bash",
            script,
            name,
            nodes,
            total_tasks,
            tasks_per_node,
            email_address,
            type
        ], check=True)

    helyx_menu = OptionNode("HELYX MENU")
    # Example action
    helyx_menu.add_child(
        OptionNode(
            name="Run pipeline",
            handler=lambda: run_pipeline("run")
        ))
    helyx_menu.add_child(
        OptionNode(
            name="Run check mesh only",
            handler=lambda: run_pipeline("check")
        ))
    return helyx_menu


def openfoam_menu_setup():
    openfoam_menu = OptionNode("OPENFOAM MENU")
    openfoam_menu.add_child(OptionNode("Run OpenFOAM Example", handler=lambda: subprocess.run(
        ["echo", "Running OpenFOAM example..."])))
    return openfoam_menu


def basilisk_menu_setup():
    basilisk_menu = OptionNode("BASILISK MENU")
    basilisk_menu.add_child(OptionNode("Run Basilisk Example", handler=lambda: subprocess.run(
        ["echo", "Running Basilisk example..."])))
    return basilisk_menu


def xcompact3d_menu_setup():
    xcompact3d_menu = OptionNode("XCOMPACT3D MENU")
    xcompact3d_menu.add_child(OptionNode("Run XCompact3D Example", handler=lambda: subprocess.run(
        ["echo", "Running XCompact3D example..."])))
    return xcompact3d_menu


def ansys_menu_setup():
    ansys_menu = OptionNode("ANSYS MENU")
    ansys_menu.add_child(OptionNode("Run ANSYS Example", handler=lambda: subprocess.run(
        ["echo", "Running ANSYS example..."])))
    return ansys_menu


def paraview_menu_setup():
    paraview_menu = OptionNode("PARAVIEW MENU")
    paraview_menu.add_child(OptionNode("Run ParaView Example", handler=lambda: subprocess.run(
        ["echo", "Running ParaView example..."])))
    return paraview_menu


def root_utils_menu_setup():
    def power_on_nodes():
        nodes = input(
            "Enter the list of nodes to power on (e.g., c[1,3,4-6], c1, c[1-12]): ")

        subprocess.run(
            ["bash", MENU_PWD + "/slurm-power/resume-program.sh", nodes], check=True)

    def power_off_nodes():
        nodes = input(
            "Enter the list of nodes to power off (e.g., c[1,3,4-6], c1, c[1-12]): ")

        subprocess.run(
            ["bash", MENU_PWD + "/slurm-power/suspend-program.sh", nodes], check=True)

    def update_menu():
        subprocess.run(
            ["bash", MENU_PWD + "/update-menu.sh"], check=True)

    utils_menu = OptionNode("ROOT UTILS MENU")
    utils_menu.add_child(OptionNode("Power on nodes", handler=power_on_nodes))
    utils_menu.add_child(OptionNode(
        "Power off nodes", handler=power_off_nodes))
    utils_menu.add_child(OptionNode(
        "Update menu", handler=update_menu))
    return utils_menu


cfd_menu = OptionNode("CFD MENU")

if UNIX_USER == "admin" or UNIX_USER == "root":
    cfd_menu.add_child(helyx_menu_setup())

for menu in [
    # openfoam_menu_setup,
    # basilisk_menu_setup,
    # xcompact3d_menu_setup,
    # ansys_menu_setup,
    # paraview_menu_setup,
]:
    cfd_menu.add_child(menu())

if UNIX_USER == "root":
    cfd_menu.add_child(root_utils_menu_setup())

# ==========================================
# Example Usage
# ==========================================


def main():
    while True:
        # Launch recursive menu starting at root
        selected = interactive_menu(cfd_menu)

        # If user backed out from root or chose to quit
        if selected is None:
            clear_screen()
            break

        # If the selected node had a command we executed above, exit the loop
        if selected.handler:
            break


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        clear_screen()

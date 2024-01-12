import argparse
import errno
import os
import pathlib
import subprocess
import sys


class bcolors:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


class AWSCodeArtifact:
    def __init__(
        self, aws_profile: str, aws_region: str, domain: str, domain_owner: str
    ) -> None:
        self._aws_profile = aws_profile
        self._aws_region = aws_region
        self._domain = domain
        self._domain_owner = domain_owner
        self._token = ""

    @property
    def token(self):
        """Get the auth token."""

        if not self._token:
            self._token = run_cmd(
                [
                    "aws",
                    "--profile",
                    self._aws_profile,
                    "--region",
                    self._aws_region,
                    "codeartifact",
                    "get-authorization-token",
                    "--domain",
                    self._domain,
                    "--domain-owner",
                    self._domain_owner,
                    "--query",
                    "authorizationToken",
                    "--output",
                    "text",
                ]
            )
        return self._token.rstrip("\n")


def print_colored(bcolor: bcolors, text: str):
    print(f"{bcolor}{text}{bcolors.ENDC}", end=None)


def tool_exists(name: str, additional_hint_text: str = None):
    try:
        devnull = open(os.devnull)
        subprocess.Popen([name], stdout=devnull, stderr=devnull).communicate()
    except OSError as e:
        if e.errno == errno.ENOENT:
            print_colored(
                bcolors.FAIL,
                f"{name} is not installed on your system.",
            )
            if additional_hint_text:
                print_colored(bcolors.BOLD, additional_hint_text)
            sys.exit(1)
    print_colored(bcolors.OKGREEN, f"{name} is installed on your system and can be configured.")


def run_cmd(cmd: list[str], input: str = ""):
    proc = subprocess.run(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, input=input
    )

    if proc.stderr:
        print_colored(bcolors.FAIL, f"{proc.stderr}")

    return proc.stdout


def ecr_login(args: argparse.Namespace):
    tool_exists("docker")
    print_colored(bcolors.BOLD, "Logging in to aws ecr...")

    ecr_token = run_cmd(
        cmd=[
            "aws",
            "--profile",
            args.aws_profile,
            "--region",
            args.aws_region,
            "ecr",
            "get-login-password",
        ]
    )

    docker_login_result = run_cmd(
        cmd=[
            "docker",
            "login",
            "--username",
            "AWS",
            "--password-stdin",
            f"{args.domain_owner}.dkr.ecr.{args.aws_region}.amazonaws.com",
        ],
        input=ecr_token,
    )
    print_colored(bcolors.OKGREEN, docker_login_result)


def configure_pip(args: argparse.Namespace, aws_codeartifact: AWSCodeArtifact):
    tool_exists("pip")
    print_colored(bcolors.BOLD, "Configuring pip...")

    set_index_url_result = run_cmd(
        [
            "pip",
            "config",
            "set",
            "global.index-url",
            f"https://aws:{aws_codeartifact.token}@{args.domain}-{args.domain_owner}.d.codeartifact.{args.aws_region}.amazonaws.com/pypi/dss/simple/",
        ]
    )
    print(set_index_url_result, end=None)

    set_extra_index_url_result = run_cmd(
        [
            "pip",
            "config",
            "set",
            "global.extra-index-url",
            f"https://aws:{aws_codeartifact.token}@{args.domain}-{args.domain_owner}.d.codeartifact.{args.aws_region}.amazonaws.com/pypi/dss-upstream/simple/",
        ]
    )
    print(set_extra_index_url_result, end=None)


def configure_poetry(args: argparse.Namespace, aws_codeartifact: AWSCodeArtifact):
    tool_exists("poetry")
    print_colored(bcolors.BOLD, "Configuring poetry...")

    set_index_url_result = run_cmd(
        [
            "poetry",
            "-vvv",
            "config",
            "repositories.dss",
            f"https://{args.domain}-{args.domain_owner}.d.codeartifact.{args.aws_region}.amazonaws.com/pypi/dss/simple/",
        ]
    )
    print(set_index_url_result, end=None)

    set_index_url_token_result = run_cmd(
        ["poetry", "config", "http-basic.dss", "aws", aws_codeartifact.token]
    )
    print(set_index_url_token_result, end=None)

    set_extra_index_url_result = run_cmd(
        [
            "poetry",
            "config",
            "repositories.dss-upstream",
            f"https://{args.domain}-{args.domain_owner}.d.codeartifact.{args.aws_region}.amazonaws.com/pypi/dss-upstream/simple/",
        ]
    )
    print(set_extra_index_url_result, end=None)

    set_extra_index_url_token_result = run_cmd(
        ["poetry", "config", "http-basic.dss-upstream", "aws", aws_codeartifact.token]
    )
    print(set_extra_index_url_token_result, end=None)


def configure_twine(args: argparse.Namespace):
    tool_exists("twine")
    print_colored(bcolors.BOLD, "Configuring twine...")

    result = run_cmd(
        cmd=[
            "aws",
            "--profile",
            args.aws_profile,
            "--region",
            args.aws_region,
            "codeartifact",
            "login",
            "--tool",
            "twine",
            "--domain",
            args.domain,
            "--domain-owner",
            args.domain_owner,
            "--repository",
            "dss",
        ]
    )
    print_colored(bcolors.OKGREEN, result)


def login(args: argparse.Namespace):
    tool_exists(
        name="aws",
        additional_hint_text="See https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html.",
    )

    sso_login(args=parsed_args)

    aws_codeartifact = AWSCodeArtifact(
        aws_profile=parsed_args.aws_profile,
        aws_region=parsed_args.aws_region,
        domain=parsed_args.domain,
        domain_owner=parsed_args.domain_owner,
    )

    if args.ecr:
        ecr_login(args=args)
    if args.pip:
        configure_pip(args=args, aws_codeartifact=aws_codeartifact)
    if args.poetry:
        configure_poetry(args=args, aws_codeartifact=aws_codeartifact)
    if args.twine:
        configure_twine(args=args)


def ecr_logout(args: argparse.Namespace):
    tool_exists("docker")

    print_colored(bcolors.BOLD, "Resetting docker...")

    docker_logout_result = run_cmd(
        cmd=[
            "docker",
            "logout",
            f"{args.domain_owner}.dkr.ecr.{args.aws_region}.amazonaws.com",
        ]
    )
    print(docker_logout_result, end=None)


def pip_logout():
    tool_exists("pip")

    print_colored(bcolors.BOLD, "Resetting pip...")
    pip_unset_result = run_cmd(cmd=["pip", "config", "unset", "global.index-url"])
    print(pip_unset_result, end=None)

    pip_unset_result = run_cmd(cmd=["pip", "config", "unset", "global.extra-index-url"])
    print(pip_unset_result, end=None)


def poetry_logout():
    tool_exists("poetry")

    print_colored(bcolors.BOLD, "Resetting poetry...")
    poetry_unset_result = run_cmd(
        cmd=["poetry", "-vvv", "config", "repositories.dss", "--unset"]
    )
    print(poetry_unset_result, end=None)

    poetry_unset_result = run_cmd(
        cmd=["poetry", "-vvv", "config", "repositories.dss-upstream", "--unset"]
    )
    print(poetry_unset_result, end=None)


def twine_logout():
    pypi_rc_path = pathlib.Path.home() / ".pypirc"
    pypi_rc_path.unlink()


def logout(args: argparse.Namespace):
    if args.ecr:
        ecr_logout(args=args)
    if args.pip:
        pip_logout()
    if args.poetry:
        poetry_logout()
    if args.twine:
        twine_logout()


def parse_args(args):
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--aws-profile", required=True)
    parser.add_argument("-r", "--aws-region", required=True)
    parser.add_argument("-d", "--domain", required=True)
    parser.add_argument(
        "-o",
        "--domain-owner-account",
        dest="domain_owner",
        required=True,
    )
    subparsers = parser.add_subparsers(dest="subparsers")

    login_command_parser = subparsers.add_parser(
        name="login", help="Command for logging in to aws services."
    )
    login_command_parser.add_argument(
        "--ecr",
        action=argparse.BooleanOptionalAction,
        help="If true, a login to ecr will be performed.",
    )
    login_command_parser.add_argument(
        "--pip",
        action=argparse.BooleanOptionalAction,
        help="If true, pip will be configured to access codeartifact.",
    )
    login_command_parser.add_argument(
        "--poetry",
        action=argparse.BooleanOptionalAction,
        help="If true, poetry will be configured to access codeartifact.",
    )
    login_command_parser.add_argument(
        "--twine",
        action=argparse.BooleanOptionalAction,
        help="If true, twine will be configured to access codeartifact.",
    )
    login_command_parser.set_defaults(func=login)

    logout_command_parser = subparsers.add_parser(
        name="logout", help="Command for logging out from aws services."
    )
    logout_command_parser.add_argument(
        "--ecr",
        action=argparse.BooleanOptionalAction,
        help="If true, a logout from ecr will be performed.",
    )
    logout_command_parser.add_argument(
        "--pip",
        action=argparse.BooleanOptionalAction,
        help="If true, pip will be reset.",
    )
    logout_command_parser.add_argument(
        "--poetry",
        action=argparse.BooleanOptionalAction,
        help="If true, poetry will be reset.",
    )
    logout_command_parser.add_argument(
        "--twine",
        action=argparse.BooleanOptionalAction,
        help="If true, twine will be reset.",
    )
    logout_command_parser.set_defaults(func=logout)
    return parser.parse_args(args=args)


def sso_login(args):
    result = run_cmd(
        cmd=[
            "aws",
            "sts",
            "get-caller-identity",
            "--query",
            "Account",
            "--profile",
            args.aws_profile,
        ]
    )
    if result:
        print_colored(bcolors.OKGREEN, f"Already logged in to account {result}")
    else:
        result = run_cmd(cmd=["aws", "sso", "login", "--profile", args.aws_profile])


if __name__ == "__main__":
    parsed_args = parse_args(sys.argv[1:])

    parsed_args.func(parsed_args)

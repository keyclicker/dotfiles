#!/usr/bin/python3
"""
This script compiles snippets from snipmate format to vscode format and
vise versa.
"""


import sys
import json
import re

HELP = """
Usage: snipc.py <snippets.snippets> <snippets.json>
"""


def compile_to_snipmate(source: str):
    """
    Compile vscode to snipmate

    Args:
        source (str): path to .json file
    """

    with open(source, "r", encoding="utf-8") as f:
        snippets = json.load(f)

    output = ""
    for name, snippet in snippets.items():
        desc = name
        if "description" in snippet:
            desc += f" - {snippet['description']}"

        output += f'snippet {snippet["prefix"]} "{desc}"\n'

        for line in snippet["body"]:
            output += 8 * " " + f"{line}\n"

        output += "\n"

    # check if file exists
    target = source.replace(".json", ".snippets")
    if target == source:
        answer = input("File alerady exist, do you want to overwrite it? [y/n]: ")

        if answer.lower() != "y":
            return

    print("output", output)
    with open(target, "w", encoding="utf-8") as f:
        f.write(output)


def compile_to_vscode(source: str):
    """
    Compile snipmate to vscode

    Args:
        source (str): path to .snippets file
    """

    with open(source, "r", encoding="utf-8") as f:
        lines = f.readlines()

    white_re = re.compile(r"$[\s]+^")
    def_re = re.compile(r"\s*snippet (?P<prefix>\w+) \"(?P<name_desc>.*)\"")
    name_desc_re = re.compile(r"^\s*(?P<name>.*)\s*-\s*(?P<desc>.*)\s*")

    snippets = {}
    cur_snip = {}
    cur_snip_name = ''
    cur_tab = 0
    line_n = 0

    state = 'init'

    for line in lines:
        line_n += 1

        if state == 'init' and white_re.match(line):
            continue

        # match regexp
        def_match = def_re.match(line)
        if def_match:
            if state != 'init':
                snippets[cur_snip_name] = cur_snip 
                cur_snip_name = ''
                cur_snip = {}

            cur_snip['prefix'] = def_match.group("prefix")

            name_desc = def_match.group("name_desc")
            name_desc_match = name_desc_re.match(name_desc)

            if name_desc_match is None:
                raise Exception(f"Invalid name description [{line_n}]: {name_desc}")

            cur_snip["name"] = name_desc_match.group("name")
            cur_snip["esc"] = name_desc_match.group("desc")

            state = 'body'

        elif 
            cur_snip['body']
            
            
    snippets[cur_snip_name] = cur_snip 

def main():
    """
    Parse command line arguments and call the appropriate function
    """

    if len(sys.argv) < 2:
        print("Usage: snipc.py <snippets.(snippets|json)>")
        return

    source = sys.argv[1]

    try:
        if source.endswith(".snippets"):
            compile_to_vscode(source)
        elif source.endswith(".json"):
            compile_to_snipmate(source)
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()

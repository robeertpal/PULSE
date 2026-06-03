import sys

with open("backend/main.py", "r") as f:
    lines = f.readlines()

in_get_my_payments = False
in_try = False

with open("backend/main.py", "w") as f:
    for i, line in enumerate(lines):
        if line.startswith("def get_my_payments("):
            in_get_my_payments = True
        if in_get_my_payments and line.strip() == "try:":
            in_try = True
            f.write(line)
            continue
        if in_try:
            if line.startswith("    except Exception as e:"):
                in_try = False
                in_get_my_payments = False
                f.write(line)
                continue
            if line.strip() == "":
                f.write(line)
            else:
                f.write("    " + line)
        else:
            f.write(line)


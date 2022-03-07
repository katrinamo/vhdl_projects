#! /usr/bin/python3.8
import sys

def ram_convert(filename: str) -> None:
    file_out = "initram_bin.txt"

    print(f"Opening {filename}...")
    with open(filename, 'r') as f:
        data_line = f.readline()

        # Maximum size of our address space is 128. Truncate if needed
        if (len(data_line) > 128):
            print("WARNING: File is longer than ram address space. Truncating to 128 characters.")
            data_line = data_line[0:128]

        with open(file_out, 'w') as fout:
            for c in data_line:
                bin_c = format(c.encode('utf-8')[0], '08b')
                fout.write(bin_c)
                fout.write("\n")

if __name__ == "__main__":
    if (len(sys.argv) != 2):
        print("Uasge: ram_convert.py [filename]")
        exit(1)

    ram_convert(sys.argv[1])

from os import path, listdir

from src.common import Data


def get_files(directory):
    """Get all paths of a given suffix in a directory."""
    return [
        path.join(directory, file)
        for file in listdir(directory)
        if file.endswith(".report")
    ]


def create_input_file_generator(filename):
    with open(filename, 'r') as file:
        for line in file:
            # strip right and left whitespace from line
            yield line.strip()


def parse_files_in_dir(directory, debug=None):
    """
    Read all the files in a given directory and parse them into one
    data structure.
    """
    data_list = []

    for filename in get_files(directory):
        if debug:
            print(f"Parse report {filename}...")

        data = Data()
        raw_data = create_input_file_generator(filename)

        for line in raw_data:
            if "#" in line:
                # ignore comments
                continue

            # first line after comments are the defined fields
            fields = [element.strip().lower() for element in line.split()]
            data.fields = fields
            break

        data.values = list(raw_data)
        data_list.append(data)
    return data_list

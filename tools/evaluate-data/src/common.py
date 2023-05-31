from dataclasses import dataclass, field
from types import SimpleNamespace
from typing import List


def adjust_arrays(data_one: 'ndarray', data_two: 'ndarray'):
    """
    If both arrays do not have the same length cut the bigger one
    to match the smaller one.
    """

    difference = data_one.size - data_two.size

    if difference == 0:
        return data_one, data_two

    abs_diff = abs(difference)

    if difference > 0:
        # data_one is bigger than data_two so data_one needs to be cut
        data_one = data_one[:-abs_diff]
    else:
        data_two = data_two[:-abs_diff]

    return data_one, data_two


class SimpleNamespaceWrapper(SimpleNamespace):
    """
    Define a wrapper class around SimpleNamespace which handles
    the case if members do not exist but get accessed. If that is the
    case return None.
    """

    def __init__(self, dictionary):
        super().__init__(**dictionary)

    def __getattribute__(self, value):
        try:
            return super().__getattribute__(value)
        except AttributeError:
            return None


@dataclass
class Data:
    fields: List[str] = field(default_factory=list)
    values: List[int] = field(default_factory=list)

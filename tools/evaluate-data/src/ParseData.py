import numpy as np

from src.calculations import scipy_geo_mean
from src.common import Data, SimpleNamespaceWrapper


def combine_data(data_list):
    """Combine multiple data objects in the list into a single data object."""

    fields, values = [], []
    for index, data in enumerate(data_list):
        if index == 0:
            # assumption: every data has the same fields so just take the
            # first one to represent every other
            fields = data.fields

        values.extend(data.values)

    return [Data(fields=fields, values=values)]


def split_into_values(data_list, single=False, no_namespace=False):
    """
    Make the parsed data available in different forms depending on the
    used flags. The found fields will be used as the order of a value line in
    the file.

    Args:
        data_list: A list containing the data to be parsed.
        single: If set to True, the function will combine the multiple files
        into a single list before parsing. Defaults to False.
        no_namespace: If set to True, the parsed data will be returned as a
        dictionary instead of a SimpleNamespace object. Defaults to False.

    """

    real_data_list = combine_data(data_list) if single else data_list
    temp_list = []

    for data in real_data_list:
        fields, values = data.fields, data.values
        values = [item.split() for item in values]

        data_dict = {}

        # TODO: Make better algo for getting a single column for a key
        for index, field in enumerate(fields):
            value_array = [element[index] for element in values]
            data_dict[field] = np.array(value_array).astype(int)

        temp = data_dict if no_namespace else SimpleNamespaceWrapper(data_dict)
        temp_list.append(temp)

    return temp_list[0] if single else temp_list


def calculate_geo_mean(orig_values, namespace=False):
    """
    Calculate the geometric mean of values with the same field.

    Args:
        orig_values: A list containing dictionaries with the original values
        for which the geometric mean needs to be calculated.
        namespace: If set to True, the function expects orig_values to be a list
        of SimpleNamespace objects.

    Returns:
        The calculated geometric mean in the form of a SimpleNamespace object.

    """
    temp_values = {}
    for values in orig_values:
        values = vars(values) if namespace else values

        for attribute in values.keys():
            value = np.mean(values.get(attribute))

            if attribute not in temp_values:
                temp_values[attribute] = [value]
            else:
                temp_values[attribute].append(value)

    return SimpleNamespaceWrapper(
        {key: scipy_geo_mean(value)
         for key, value in temp_values.items()}
    )

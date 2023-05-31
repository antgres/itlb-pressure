import numpy as np
import matplotlib.pyplot as plt

from src.common import adjust_arrays


def create_label(plot, array):
    """
    Make label with calculated mean and standard deviation information for
    given array.
    """
    # \u03BC = µ ; \u03C3 = sigma
    return f'{plot}\n\u03BC: {np.mean(array):.4f}\n\u03C3: {np.std(array):.4f}'


def create_histogram(field, array_optimized, array_unoptimized):
    print(f"Creating graph '{field}'")

    array_optimized, array_unoptimized = \
        adjust_arrays(array_optimized, array_unoptimized)

    opt = create_label("optimized", array_optimized)
    unopt = create_label("unoptimized", array_unoptimized)

    fig, ax = plt.subplots()
    ax.hist([array_optimized, array_unoptimized],
            bins="fd",
            color=['g', 'r'],
            alpha=0.5,
            label=[opt, unopt]
            )

    ax.legend(title=field, loc='upper right', fontsize=20, title_fontsize=20)
    ax.set_xlabel("Number of observed values in a given time duration",
                  fontsize=15)
    ax.set_ylabel("Number of total observed values", fontsize=15)

    plt.show()

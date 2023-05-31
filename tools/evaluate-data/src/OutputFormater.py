from src.common import adjust_arrays


def print_comparison(method, name,
                     vale_optimized, value_unoptimized,
                     type, arrow="down"):
    func = OutputFormat(method, type, arrow)
    func.print_output(name, vale_optimized, value_unoptimized)


class OutputFormat:
    def __init__(self, func, type, arrow):
        self.func, self.type, self.char = func, type, arrow
        self.arrow = '▲' if self.char == "up" else '▼'

    def _sign(self, value):
        if value > 0:
            return "good" if self.char == "up" else "bad"
        else:
            return "bad" if self.char == "up" else "good"

    def _round_value(self, value, length=4):
        return self.type(round(value, length))

    def _output(self, value):
        return self._round_value(self.func(value))

    def _calc_diff(self, value_unopt, value_opt):
        percentage = - (1 - value_opt / value_unopt) * 100
        return round(percentage, 3)

    def print_output(self, name, value_optimized, value_unoptimized):
        if value_optimized is None or value_unoptimized is None:
            print(
                f"WARNING: Values associated with the field "
                f"'{name}' are not defined.")
            return

        value_optimized, value_unoptimized = \
            adjust_arrays(value_optimized, value_unoptimized)

        value_unopt = self._output(value_unoptimized)
        value_opt = self._output(value_optimized)
        diff = self._calc_diff(value_unopt, value_opt)

        print(f"{self.arrow} {name:40s}"
              f"unopt {str(value_unopt):12s}"
              f"opt {str(value_opt):12s}"
              f"diff_opt%: {str(diff):9s} {self._sign(diff)}"
              )

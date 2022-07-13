#! /usr/bin/env python3

# To estimate fortnightly disposable income.
# Tue 05/07/2022


gross = $$$$    # Gross income
employer = $$$$     # % employer super contribution


def calc_tax(income):
    # https://www.ato.gov.au/Rates/Individual-income-tax-rates/
    base_rate = 5095
    over_amt = 45000
    cents = 32.5e-2
    return base_rate + (income-over_amt)*cents


def base_income(income, pc):
    return income-(pc*income)


def fortnightly(base, tax):
    return 2*(base-tax)/52.0


def main():
    base = base_income(gross, employer)
    tax = calc_tax(base)
    smiley = fortnightly(base, tax)
    print(f"{smiley:.2f}")


if __name__ == "__main__":
    main()

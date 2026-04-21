import pytest

from app.math_engine import UnsafeExpressionError, evaluate


@pytest.mark.parametrize(
    "expr,expected",
    [
        ("1+2", 3),
        ("2*3+4", 10),
        ("(1+2)*3", 9),
        ("10/4", 2.5),
        ("2**10", 1024),
        ("-5+3", -2),
        ("7%3", 1),
        ("7//2", 3),
    ],
)
def test_evaluate_valid(expr, expected):
    assert evaluate(expr) == expected


@pytest.mark.parametrize(
    "expr",
    [
        "",
        "x=1",
        "__import__('os').system('ls')",
        "abs(-1)",
        "a+b",
        "1+",
    ],
)
def test_evaluate_invalid(expr):
    with pytest.raises(UnsafeExpressionError):
        evaluate(expr)


def test_infinite_result_rejected():
    with pytest.raises(UnsafeExpressionError):
        evaluate("1/0.0**-1")

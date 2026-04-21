"""Safe arithmetic expression evaluator.

Only supports +, -, *, /, %, **, parentheses and numeric literals.
No names, no calls, no attribute access — prevents arbitrary code execution.
"""
from __future__ import annotations

import ast
import math
import operator as op

_BIN_OPS = {
    ast.Add: op.add,
    ast.Sub: op.sub,
    ast.Mult: op.mul,
    ast.Div: op.truediv,
    ast.Mod: op.mod,
    ast.Pow: op.pow,
    ast.FloorDiv: op.floordiv,
}

_UNARY_OPS = {
    ast.UAdd: op.pos,
    ast.USub: op.neg,
}


class UnsafeExpressionError(ValueError):
    """Raised when an expression contains disallowed nodes."""


def _eval(node: ast.AST) -> float:
    if isinstance(node, ast.Expression):
        return _eval(node.body)
    if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
        return node.value
    if isinstance(node, ast.BinOp) and type(node.op) in _BIN_OPS:
        try:
            return _BIN_OPS[type(node.op)](_eval(node.left), _eval(node.right))
        except ArithmeticError as e:
            raise UnsafeExpressionError(f"Arithmetic error: {e}") from e
    if isinstance(node, ast.UnaryOp) and type(node.op) in _UNARY_OPS:
        return _UNARY_OPS[type(node.op)](_eval(node.operand))
    raise UnsafeExpressionError(f"Disallowed expression node: {type(node).__name__}")


def evaluate(expression: str) -> float:
    if not expression or len(expression) > 256:
        raise UnsafeExpressionError("Expression must be 1..256 chars")
    try:
        tree = ast.parse(expression, mode="eval")
    except SyntaxError as e:
        raise UnsafeExpressionError(f"Invalid syntax: {e}") from e
    result = _eval(tree)
    if isinstance(result, float) and (math.isnan(result) or math.isinf(result)):
        raise UnsafeExpressionError("Result is not finite")
    return result

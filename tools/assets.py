"""Invoke the example-owned asset recipe without making it part of the library."""
import importlib.util
from pathlib import Path
_path = Path(__file__).resolve().parents[1] / "examples/asteroids/assets/generate.py"
_spec = importlib.util.spec_from_file_location("asteroids_assets", _path)
_recipe = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_recipe)
generate = _recipe.generate

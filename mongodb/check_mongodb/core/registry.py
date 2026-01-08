# core/registry.py
import os
import importlib
import pkgutil

class PluginRegistry:
    _commands = {}

    @classmethod
    def register(cls, name, help_msg):
        def decorator(func):
            cls._commands[name] = {'func': func, 'help': help_msg}
            return func
        return decorator

    @classmethod
    def load_plugins(cls):
        import commands 
        package = commands
        prefix = package.__name__ + "."

        for _, name, _ in pkgutil.iter_modules(package.__path__, prefix):
            try:
                importlib.import_module(name)
            except Exception as e:
                print(f"Error loading plugin {name}: {e}")

    @classmethod
    def get_commands(cls):
        return cls._commands
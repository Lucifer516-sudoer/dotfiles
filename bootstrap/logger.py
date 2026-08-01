import datetime
import logging
import logging.config
from typing import Any

from .constants import LOGS_DIR


class NativeColoredFormatter(logging.Formatter):
    RESET = "\033[0m"

    COLORS = {
        logging.DEBUG: "\033[36m",  # Cyan
        logging.INFO: "\033[32m",  # Green
        logging.WARNING: "\033[33m",  # Yellow
        logging.ERROR: "\033[31m",  # Red
        logging.CRITICAL: "\033[1;31m",  # Bold Red
    }

    def format(self, record: logging.LogRecord):
        # 1. Format the line cleanly. This does NOT change the record object.
        formatted_line = super().format(record)

        # 2. Get color for the terminal
        log_color = self.COLORS.get(record.levelno, "")

        # 3. Only colorize the final string returned to the console handler
        if log_color:
            return f"{log_color}{formatted_line}{self.RESET}"
        return formatted_line


LOGGING_CONFIG: dict[str, Any] = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "plain": {
            "format": "%(asctime)s [%(levelname)-8s] %(name)s: %(message)s",
            "datefmt": "%Y-%m-%d %H:%M:%S",
        },
        "colored": {
            "()": NativeColoredFormatter,
            "format": "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
            "datefmt": "%Y-%m-%d %H:%M:%S",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "colored",  # ANSI codes on terminal
            "level": "INFO",
            "stream": "ext://sys.stdout",
        },
        "file": {
            "class": "logging.handlers.RotatingFileHandler",
            "formatter": "plain",  # No ANSI codes in text files
            "level": "DEBUG",
            "filename": str(
                LOGS_DIR
                / f"bootstrap_{datetime.datetime.now().strftime('%d_%b_%Y_%H_%M')}.log"
            ),
            "maxBytes": 10485760,
            "backupCount": 5,
            "encoding": "utf8",
        },
    },
    "root": {
        "handlers": ["console", "file"],
        "level": "DEBUG",
    },
}

# Apply and test
logging.config.dictConfig(LOGGING_CONFIG)
logger = logging.getLogger("bootstrapper")

"""Metrics collector.

Simple metrics collection for monitoring.
"""

import time
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Any


@dataclass
class MetricsCollector:
    """Collects and exposes operational metrics."""

    _counters: dict[str, int] = field(default_factory=lambda: defaultdict(int))
    _gauges: dict[str, float] = field(default_factory=dict)
    _histograms: dict[str, list[float]] = field(
        default_factory=lambda: defaultdict(list)
    )

    def increment(self, name: str, value: int = 1) -> None:
        """Increment a counter.

        Args:
            name: Counter name.
            value: Increment value.
        """
        self._counters[name] += value

    def gauge(self, name: str, value: float) -> None:
        """Set a gauge value.

        Args:
            name: Gauge name.
            value: Gauge value.
        """
        self._gauges[name] = value

    def observe(self, name: str, value: float) -> None:
        """Add observation to histogram.

        Args:
            name: Histogram name.
            value: Observed value.
        """
        self._histograms[name].append(value)

    def time(self, name: str) -> "Timer":
        """Create a timer context manager.

        Args:
            name: Metric name for the duration.

        Returns:
            Timer context manager.
        """
        return Timer(self, name)

    def get_metrics(self) -> dict[str, Any]:
        """Get all metrics.

        Returns:
            Dictionary of all metrics.
        """
        result: dict[str, Any] = {
            "counters": dict(self._counters),
            "gauges": dict(self._gauges),
            "histograms": {},
        }

        for name, values in self._histograms.items():
            if values:
                result["histograms"][name] = {
                    "count": len(values),
                    "sum": sum(values),
                    "min": min(values),
                    "max": max(values),
                    "avg": sum(values) / len(values),
                }

        return result

    def reset(self) -> None:
        """Reset all metrics."""
        self._counters.clear()
        self._gauges.clear()
        self._histograms.clear()


class Timer:
    """Context manager for timing operations."""

    def __init__(self, collector: MetricsCollector, name: str) -> None:
        """Initialize timer.

        Args:
            collector: Metrics collector.
            name: Metric name.
        """
        self.collector = collector
        self.name = name
        self.start_time: float = 0

    def __enter__(self) -> "Timer":
        """Start timing."""
        self.start_time = time.perf_counter()
        return self

    def __exit__(self, *args: Any) -> None:
        """Stop timing and record duration."""
        duration = time.perf_counter() - self.start_time
        self.collector.observe(self.name, duration)

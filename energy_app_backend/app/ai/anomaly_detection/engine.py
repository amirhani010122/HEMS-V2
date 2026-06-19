"""
محرك اكتشاف الاستهلاك الغريب (Anomaly Detection).
"""
from typing import Dict, Any, List
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class AnomalyEngine:
    """محرك اكتشاف الحالات الشاذة في الاستهلاك."""

    def detect(
        self,
        daily_data: List[Dict[str, Any]],
        per_device_data: List[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        اكتشاف anomalies في بيانات الاستهلاك.

        Args:
            daily_data: بيانات يومية (آخر 7-30 يوم)
            per_device_data: بيانات لكل جهاز (اختياري)

        Returns:
            تقرير anomalies
        """
        anomalies = []

        if not daily_data or len(daily_data) < 3:
            return {
                "anomalies": [],
                "summary": "Not enough data for anomaly detection.",
                "status": "ok",
                "total_anomalies": 0,
            }

        # ═══════════════════════════════════════
        # 1. Spike Detection
        # ═══════════════════════════════════════
        values = [d.get("total", d.get("consumption", 0)) for d in daily_data]
        dates = [d.get("date", "") for d in daily_data]

        avg = sum(values) / len(values)
        
        # الانحراف المعياري
        variance = sum((v - avg) ** 2 for v in values) / len(values)
        std_dev = variance ** 0.5

        # الحد الأعلى والأدنى (2 انحراف معياري)
        upper_bound = avg + (2 * std_dev)
        lower_bound = max(0, avg - (2 * std_dev))

        for i, (val, date) in enumerate(zip(values, dates)):
            if val > upper_bound and val > avg * 1.5:  # Spike
                severity = "critical" if val > upper_bound * 1.5 else "high"
                anomalies.append({
                    "type": "spike",
                    "date": date,
                    "value": round(val, 2),
                    "expected": round(avg, 2),
                    "upper_bound": round(upper_bound, 2),
                    "severity": severity,
                    "message": (
                        f"Unusual spike: {val:.1f} kWh on {date} "
                        f"(expected ~{avg:.1f} kWh)"
                    ),
                })
            elif val < lower_bound and avg > 1.0:  # Drop
                anomalies.append({
                    "type": "drop",
                    "date": date,
                    "value": round(val, 2),
                    "expected": round(avg, 2),
                    "lower_bound": round(lower_bound, 2),
                    "severity": "medium",
                    "message": (
                        f"Unusual drop: {val:.1f} kWh on {date} "
                        f"(expected ~{avg:.1f} kWh)"
                    ),
                })

        # ═══════════════════════════════════════
        # 2. Trend Analysis
        # ═══════════════════════════════════════
        if len(values) >= 7:
            first_half = values[:len(values)//2]
            second_half = values[len(values)//2:]
            avg_first = sum(first_half) / len(first_half)
            avg_second = sum(second_half) / len(second_half)

            if avg_first > 0:
                change_pct = ((avg_second - avg_first) / avg_first) * 100
                if abs(change_pct) >= 30:  # تغير > 30%
                    anomalies.append({
                        "type": "trend_change",
                        "date": dates[-1],
                        "value": round(avg_second, 2),
                        "previous_avg": round(avg_first, 2),
                        "change_percent": round(change_pct, 1),
                        "severity": "medium",
                        "message": (
                            f"Consumption {'increased' if change_pct > 0 else 'decreased'} "
                            f"by {abs(change_pct):.0f}% compared to previous period"
                        ),
                    })

        # ═══════════════════════════════════════
        # 3. Per-Device Anomaly (اختياري)
        # ═══════════════════════════════════════
        if per_device_data:
            device_anomalies = self._detect_device_anomalies(per_device_data)
            anomalies.extend(device_anomalies)

        # ═══════════════════════════════════════
        # 4. Build Summary
        # ═══════════════════════════════════════
        total = len(anomalies)
        if total == 0:
            status = "ok"
            summary = "No anomalies detected. Consumption is normal."
        elif total <= 2:
            status = "warning"
            summary = f"{total} minor anomalies detected."
        else:
            status = "critical"
            summary = f"{total} anomalies detected! Review your consumption."

        return {
            "anomalies": anomalies[:10],  # الحد الأقصى 10
            "summary": summary,
            "status": status,
            "total_anomalies": total,
            "stats": {
                "average_daily": round(avg, 2),
                "std_dev": round(std_dev, 2),
                "upper_bound": round(upper_bound, 2),
                "lower_bound": round(lower_bound, 2),
                "days_analyzed": len(daily_data),
            },
        }

    def _detect_device_anomalies(
        self,
        per_device_data: List[Dict[str, Any]],
    ) -> List[Dict[str, Any]]:
        """اكتشاف anomalies على مستوى الأجهزة."""
        anomalies = []

        # تجميع حسب الجهاز
        device_values: Dict[str, List[float]] = {}
        for item in per_device_data:
            name = item.get("device_name", "unknown")
            val = item.get("total", item.get("consumption", 0))
            if name not in device_values:
                device_values[name] = []
            device_values[name].append(val)

        for device_name, values in device_values.items():
            if len(values) < 3:
                continue

            avg = sum(values) / len(values)
            for i, val in enumerate(values):
                if avg > 0 and val > avg * 3:  # 3× المتوسط
                    anomalies.append({
                        "type": "device_spike",
                        "device": device_name,
                        "value": round(val, 2),
                        "expected": round(avg, 2),
                        "severity": "high",
                        "message": (
                            f"Device '{device_name}' spiked to {val:.1f} kWh "
                            f"(normal: ~{avg:.1f} kWh)"
                        ),
                    })

        return anomalies
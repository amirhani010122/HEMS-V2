# ل lazy import
def get_forecasting_engine():
    from app.ai.forecasting.engine import ForecastingEngine
    return ForecastingEngine

def get_forecasting_service():
    from app.ai.forecasting.service import ForecastingService
    return ForecastingService
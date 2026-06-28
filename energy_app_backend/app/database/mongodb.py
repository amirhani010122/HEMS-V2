from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from beanie import init_beanie
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)


class Database:
    client: AsyncIOMotorClient = None
    db: AsyncIOMotorDatabase = None


db = Database()


async def connect_to_mongo():
    """Connect to MongoDB."""
    logger.info(f"Connecting to MongoDB: {settings.MONGODB_URL}")

#     # الرابط المباشر للمونجو الداخلي في ريلواي
# url_direct = "mongodb://mongo:luFjsELLtZup1JsQ@mongodb.railway.internal:27017/?authSource=admin"

# db.client = AsyncIOMotorClient(url_direct)
# db.db = db.client["hems_db"]
    # الرابط المباشر المؤمن للمونجو الداخلي في ريلواي
url_direct = "mongodb://mongo:luFjsELLtZup1JsQ@mongodb.railway.internal:27017/?authSource=admin"

db.client = AsyncIOMotorClient(url_direct)
db.db = db.client["hems_db"]

    # Test connection
    try:
        await db.client.admin.command("ping")
        logger.info("Successfully connected to MongoDB")
    except Exception as e:
        logger.error(f"Failed to connect to MongoDB: {e}")
        raise


async def close_mongo_connection():
    """Close MongoDB connection."""
    if db.client:
        logger.info("Closing MongoDB connection")
        db.client.close()


async def init_db():
    """Initialize database collections and indexes."""
    from app.auth.models import User, RefreshToken
    from app.devices.models import Device, DeviceCommand
    from app.consumption.models import ConsumptionRecord, DailyAggregation, MonthlyAggregation
    from app.plans.models import Plan, Subscription
    from app.alerts.models import Alert
    from app.ai.forecasting.models import ForecastingResult
    from app.ai.anomaly_detection.models import AnomalyDetectionResult
    from app.ai.smart_advisor.models import Recommendation, SavingPlan

    try:
        await init_beanie(
            database=db.db,
            document_models=[
                User,
                RefreshToken,
                Device,
                DeviceCommand,
                ConsumptionRecord,
                DailyAggregation,
                MonthlyAggregation,
                Plan,
                Subscription,
                Alert,
                ForecastingResult,
                AnomalyDetectionResult,
                Recommendation,
                SavingPlan,
            ],
        )
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        raise


def get_db() -> AsyncIOMotorDatabase:
    """Get database instance."""
    return db.db

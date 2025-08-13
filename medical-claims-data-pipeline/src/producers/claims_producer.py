"""
Medical Claims Kafka Producer

This module handles the production of medical claims data to Kafka topics
for real-time streaming processing.
"""

import json
import logging
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from decimal import Decimal

from kafka import KafkaProducer
from kafka.errors import KafkaError, KafkaTimeoutError
from confluent_kafka import Producer as ConfluentProducer
from confluent_kafka.admin import AdminClient, NewTopic

from ..models.claims_schema import MedicalClaim, ClaimBatch, ClaimType, ClaimStatus
from ..utils.config import get_config
from ..utils.logger import get_logger
from ..utils.metrics import MetricsCollector


class ClaimsProducer:
    """
    Producer for medical claims data to Kafka topics.
    
    Handles:
    - Real-time claim streaming
    - Batch claim processing
    - Data validation before sending
    - Error handling and retry logic
    - Metrics collection
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the claims producer.
        
        Args:
            config: Configuration dictionary, uses default if not provided
        """
        self.config = config or get_config()
        self.logger = get_logger(__name__)
        self.metrics = MetricsCollector()
        
        # Kafka configuration
        self.bootstrap_servers = self.config.get('kafka.bootstrap_servers', 'localhost:9092')
        self.topic_raw = self.config.get('kafka.topics.raw', 'medical-claims-raw')
        self.topic_validated = self.config.get('kafka.topics.validated', 'medical-claims-validated')
        self.topic_alerts = self.config.get('kafka.topics.alerts', 'medical-claims-alerts')
        
        # Producer configuration
        self.producer_config = {
            'bootstrap_servers': self.bootstrap_servers,
            'value_serializer': lambda v: json.dumps(v, default=str).encode('utf-8'),
            'key_serializer': lambda k: k.encode('utf-8') if k else None,
            'acks': 'all',
            'retries': 3,
            'batch_size': 16384,
            'linger_ms': 10,
            'buffer_memory': 33554432,
            'max_request_size': 1048576,
            'compression_type': 'snappy',
            'enable_idempotence': True,
            'max_in_flight_requests_per_connection': 5,
            'request_timeout_ms': 30000,
            'delivery_timeout_ms': 120000,
        }
        
        # Initialize producer
        self.producer = None
        self._initialize_producer()
        
        # Topic management
        self._ensure_topics_exist()
        
        # Statistics
        self.stats = {
            'messages_sent': 0,
            'messages_failed': 0,
            'bytes_sent': 0,
            'last_send_time': None,
            'errors': []
        }
    
    def _initialize_producer(self):
        """Initialize the Kafka producer with error handling."""
        try:
            self.producer = KafkaProducer(**self.producer_config)
            self.logger.info(f"Kafka producer initialized successfully for {self.bootstrap_servers}")
            
            # Set up callback handlers
            self.producer.add_callback(self._on_send_success)
            self.producer.add_callback(self._on_send_error)
            
        except Exception as e:
            self.logger.error(f"Failed to initialize Kafka producer: {e}")
            raise
    
    def _ensure_topics_exist(self):
        """Ensure required Kafka topics exist."""
        try:
            admin_client = AdminClient({'bootstrap.servers': self.bootstrap_servers})
            
            topics = [
                NewTopic(self.topic_raw, num_partitions=6, replication_factor=3),
                NewTopic(self.topic_validated, num_partitions=6, replication_factor=3),
                NewTopic(self.topic_alerts, num_partitions=3, replication_factor=3)
            ]
            
            # Create topics if they don't exist
            futures = admin_client.create_topics(topics)
            
            for topic, future in futures.items():
                try:
                    future.result(timeout=30)
                    self.logger.info(f"Topic {topic} created successfully")
                except Exception as e:
                    if "already exists" not in str(e):
                        self.logger.warning(f"Topic {topic} creation issue: {e}")
            
            admin_client.close()
            
        except Exception as e:
            self.logger.warning(f"Topic creation check failed: {e}")
    
    def _on_send_success(self, record_metadata):
        """Callback for successful message sends."""
        self.stats['messages_sent'] += 1
        self.stats['bytes_sent'] += len(record_metadata.value) if record_metadata.value else 0
        self.stats['last_send_time'] = datetime.utcnow()
        
        # Update metrics
        self.metrics.increment_counter('kafka_messages_sent_total', 
                                     labels={'topic': record_metadata.topic})
        self.metrics.observe_histogram('kafka_message_size_bytes', 
                                     len(record_metadata.value) if record_metadata.value else 0,
                                     labels={'topic': record_metadata.topic})
        
        self.logger.debug(f"Message sent successfully to {record_metadata.topic} "
                         f"partition {record_metadata.partition} "
                         f"offset {record_metadata.offset}")
    
    def _on_send_error(self, exc):
        """Callback for failed message sends."""
        self.stats['messages_failed'] += 1
        self.stats['errors'].append({
            'timestamp': datetime.utcnow(),
            'error': str(exc)
        })
        
        # Update metrics
        self.metrics.increment_counter('kafka_messages_failed_total')
        
        self.logger.error(f"Message send failed: {exc}")
    
    def send_claim(self, claim: MedicalClaim, topic: Optional[str] = None) -> bool:
        """
        Send a single medical claim to Kafka.
        
        Args:
            claim: Medical claim to send
            topic: Target topic (defaults to raw claims topic)
            
        Returns:
            bool: True if sent successfully, False otherwise
        """
        try:
            # Validate claim before sending
            if not self._validate_claim(claim):
                self.logger.warning(f"Claim validation failed for claim {claim.claim_id}")
                return False
            
            # Determine topic
            target_topic = topic or self.topic_raw
            
            # Prepare message
            message = self._prepare_claim_message(claim)
            key = claim.claim_id
            
            # Send message
            future = self.producer.send(
                topic=target_topic,
                key=key,
                value=message,
                headers=[
                    ('claim_type', claim.claim_type.encode('utf-8')),
                    ('provider_id', claim.provider.provider_id.encode('utf-8')),
                    ('timestamp', str(int(time.time())).encode('utf-8'))
                ]
            )
            
            # Wait for send completion
            record_metadata = future.get(timeout=30)
            
            self.logger.info(f"Claim {claim.claim_id} sent successfully to {target_topic}")
            return True
            
        except KafkaTimeoutError:
            self.logger.error(f"Timeout sending claim {claim.claim_id}")
            self.stats['messages_failed'] += 1
            return False
            
        except Exception as e:
            self.logger.error(f"Error sending claim {claim.claim_id}: {e}")
            self.stats['messages_failed'] += 1
            return False
    
    def send_claim_batch(self, batch: ClaimBatch, topic: Optional[str] = None) -> Dict[str, int]:
        """
        Send a batch of medical claims to Kafka.
        
        Args:
            batch: Batch of claims to send
            topic: Target topic (defaults to raw claims topic)
            
        Returns:
            Dict with success/failure counts
        """
        results = {
            'total': len(batch.claims),
            'successful': 0,
            'failed': 0
        }
        
        target_topic = topic or self.topic_raw
        
        self.logger.info(f"Starting to send batch {batch.batch_id} with {len(batch.claims)} claims")
        
        for claim in batch.claims:
            try:
                if self.send_claim(claim, target_topic):
                    results['successful'] += 1
                else:
                    results['failed'] += 1
                    
                # Small delay to prevent overwhelming the broker
                time.sleep(0.01)
                
            except Exception as e:
                self.logger.error(f"Error processing claim {claim.claim_id} in batch: {e}")
                results['failed'] += 1
        
        # Flush producer to ensure all messages are sent
        self.producer.flush()
        
        self.logger.info(f"Batch {batch.batch_id} completed: {results['successful']} successful, "
                        f"{results['failed']} failed")
        
        return results
    
    def send_alert(self, alert_data: Dict[str, Any], claim_id: str) -> bool:
        """
        Send an alert message to the alerts topic.
        
        Args:
            alert_data: Alert data to send
            claim_id: ID of the claim that triggered the alert
            
        Returns:
            bool: True if sent successfully, False otherwise
        """
        try:
            message = {
                'alert_id': f"alert_{int(time.time())}_{claim_id}",
                'claim_id': claim_id,
                'alert_type': alert_data.get('type', 'unknown'),
                'severity': alert_data.get('severity', 'medium'),
                'message': alert_data.get('message', ''),
                'timestamp': datetime.utcnow().isoformat(),
                'metadata': alert_data.get('metadata', {})
            }
            
            future = self.producer.send(
                topic=self.topic_alerts,
                key=claim_id,
                value=message
            )
            
            record_metadata = future.get(timeout=10)
            
            self.logger.info(f"Alert sent successfully for claim {claim_id}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to send alert for claim {claim_id}: {e}")
            return False
    
    def _validate_claim(self, claim: MedicalClaim) -> bool:
        """
        Validate a medical claim before sending.
        
        Args:
            claim: Medical claim to validate
            
        Returns:
            bool: True if valid, False otherwise
        """
        try:
            # Basic validation
            if not claim.claim_id or not claim.claim_number:
                return False
            
            if not claim.patient or not claim.provider or not claim.insurance:
                return False
            
            if not claim.claim_lines or len(claim.claim_lines) == 0:
                return False
            
            # Validate amounts
            if claim.total_billed_amount <= 0:
                return False
            
            # Validate dates
            if claim.date_of_service > datetime.utcnow():
                return False
            
            return True
            
        except Exception as e:
            self.logger.error(f"Claim validation error: {e}")
            return False
    
    def _prepare_claim_message(self, claim: MedicalClaim) -> Dict[str, Any]:
        """
        Prepare claim data for Kafka transmission.
        
        Args:
            claim: Medical claim to prepare
            
        Returns:
            Dict: Prepared message data
        """
        # Convert to dict and handle Decimal serialization
        message = claim.dict()
        
        # Add processing metadata
        message['_metadata'] = {
            'produced_at': datetime.utcnow().isoformat(),
            'producer_version': '1.0.0',
            'schema_version': '1.0.0'
        }
        
        return message
    
    def get_stats(self) -> Dict[str, Any]:
        """Get producer statistics."""
        return {
            **self.stats,
            'producer_config': {
                'bootstrap_servers': self.bootstrap_servers,
                'topics': {
                    'raw': self.topic_raw,
                    'validated': self.topic_validated,
                    'alerts': self.topic_alerts
                }
            }
        }
    
    def health_check(self) -> bool:
        """Check if the producer is healthy."""
        try:
            # Try to get metadata for a topic
            self.producer.partitions_for(self.topic_raw)
            return True
        except Exception as e:
            self.logger.error(f"Health check failed: {e}")
            return False
    
    def close(self):
        """Close the producer and cleanup resources."""
        try:
            if self.producer:
                self.producer.flush()
                self.producer.close()
                self.logger.info("Kafka producer closed successfully")
        except Exception as e:
            self.logger.error(f"Error closing producer: {e}")


class ClaimsProducerFactory:
    """Factory for creating claims producers with different configurations."""
    
    @staticmethod
    def create_producer(environment: str = 'dev', config: Optional[Dict[str, Any]] = None) -> ClaimsProducer:
        """
        Create a claims producer for the specified environment.
        
        Args:
            environment: Environment name (dev, staging, prod)
            config: Optional configuration override
            
        Returns:
            ClaimsProducer: Configured producer instance
        """
        if config is None:
            config = get_config()
        
        # Environment-specific configurations
        env_configs = {
            'dev': {
                'kafka.bootstrap_servers': 'localhost:9092',
                'kafka.topics.raw': 'medical-claims-raw-dev',
                'kafka.topics.validated': 'medical-claims-validated-dev',
                'kafka.topics.alerts': 'medical-claims-alerts-dev'
            },
            'staging': {
                'kafka.bootstrap_servers': 'staging-kafka:9092',
                'kafka.topics.raw': 'medical-claims-raw-staging',
                'kafka.topics.validated': 'medical-claims-validated-staging',
                'kafka.topics.alerts': 'medical-claims-alerts-staging'
            },
            'prod': {
                'kafka.bootstrap_servers': 'prod-kafka:9092',
                'kafka.topics.raw': 'medical-claims-raw',
                'kafka.topics.validated': 'medical-claims-validated',
                'kafka.topics.alerts': 'medical-claims-alerts'
            }
        }
        
        # Merge configurations
        if environment in env_configs:
            config.update(env_configs[environment])
        
        return ClaimsProducer(config)


# Example usage
if __name__ == "__main__":
    # Create producer
    producer = ClaimsProducerFactory.create_producer('dev')
    
    try:
        # Example claim data
        from ..models.claims_schema import MedicalClaim, Patient, Provider, Insurance, ClaimLine, ProcedureCode, DiagnosisCode
        
        # Create sample claim
        claim = MedicalClaim(
            claim_number="CLM001",
            claim_type=ClaimType.MEDICAL,
            patient=Patient(
                patient_id="PAT001",
                member_id="MEM001",
                first_name="John",
                last_name="Doe",
                date_of_birth=datetime(1980, 1, 1),
                gender="M",
                address={"street": "123 Main St", "city": "Anytown", "state": "CA", "zip": "12345"}
            ),
            provider=Provider(
                provider_id="PROV001",
                name="Dr. Smith",
                type="physician",
                npi="1234567890",
                address={"street": "456 Medical Dr", "city": "Anytown", "state": "CA", "zip": "12345"}
            ),
            insurance=Insurance(
                insurance_id="INS001",
                payer_name="Health Insurance Co",
                payer_id="PAYER001",
                group_number="GRP001",
                subscriber_number="SUB001",
                plan_type="PPO",
                coverage_start_date=datetime(2023, 1, 1)
            ),
            claim_lines=[
                ClaimLine(
                    procedure_code=ProcedureCode(
                        code="99213",
                        description="Office visit, established patient, 20-29 minutes"
                    ),
                    diagnosis_codes=[
                        DiagnosisCode(
                            code="Z00.00",
                            description="Encounter for general adult medical examination without abnormal findings",
                            primary=True
                        )
                    ],
                    service_date=datetime(2023, 8, 1),
                    billed_amount=Decimal("150.00"),
                    place_of_service="11",
                    rendering_provider_id="PROV001"
                )
            ],
            total_billed_amount=Decimal("150.00"),
            date_of_service=datetime(2023, 8, 1)
        )
        
        # Send claim
        success = producer.send_claim(claim)
        print(f"Claim sent: {success}")
        
        # Get stats
        stats = producer.get_stats()
        print(f"Producer stats: {stats}")
        
    finally:
        producer.close()

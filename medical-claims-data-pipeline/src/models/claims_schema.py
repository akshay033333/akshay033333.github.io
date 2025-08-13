"""
Medical Claims Data Schema

This module defines the data models for medical claims processing,
ensuring data consistency and validation throughout the pipeline.
"""

from datetime import datetime
from decimal import Decimal
from enum import Enum
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, validator
import uuid


class ClaimType(str, Enum):
    """Types of medical claims"""
    MEDICAL = "medical"
    DENTAL = "dental"
    VISION = "vision"
    PRESCRIPTION = "prescription"
    LABORATORY = "laboratory"
    RADIOLOGY = "radiology"
    SURGERY = "surgery"
    EMERGENCY = "emergency"
    PREVENTIVE = "preventive"


class ClaimStatus(str, Enum):
    """Status of medical claims"""
    SUBMITTED = "submitted"
    UNDER_REVIEW = "under_review"
    APPROVED = "approved"
    DENIED = "denied"
    PAID = "paid"
    APPEALED = "appealed"
    CLOSED = "closed"


class ProviderType(str, Enum):
    """Types of healthcare providers"""
    PHYSICIAN = "physician"
    HOSPITAL = "hospital"
    CLINIC = "clinic"
    LABORATORY = "laboratory"
    PHARMACY = "pharmacy"
    SPECIALIST = "specialist"
    NURSE_PRACTITIONER = "nurse_practitioner"
    PHYSICIAN_ASSISTANT = "physician_assistant"


class DiagnosisCode(BaseModel):
    """ICD-10 diagnosis code"""
    code: str = Field(..., description="ICD-10 diagnosis code")
    description: str = Field(..., description="Diagnosis description")
    primary: bool = Field(default=False, description="Primary diagnosis flag")
    severity: Optional[str] = Field(None, description="Severity level")


class ProcedureCode(BaseModel):
    """CPT/HCPCS procedure code"""
    code: str = Field(..., description="CPT/HCPCS procedure code")
    description: str = Field(..., description="Procedure description")
    modifier: Optional[str] = Field(None, description="Procedure modifier")
    units: int = Field(default=1, description="Number of units")


class ClaimLine(BaseModel):
    """Individual line item in a medical claim"""
    line_id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="Unique line identifier")
    procedure_code: ProcedureCode = Field(..., description="Procedure performed")
    diagnosis_codes: List[DiagnosisCode] = Field(..., description="Related diagnosis codes")
    service_date: datetime = Field(..., description="Date of service")
    billed_amount: Decimal = Field(..., description="Amount billed")
    allowed_amount: Optional[Decimal] = Field(None, description="Amount allowed by insurance")
    paid_amount: Optional[Decimal] = Field(None, description="Amount paid by insurance")
    place_of_service: str = Field(..., description="Place of service code")
    rendering_provider_id: str = Field(..., description="Provider who rendered the service")
    
    @validator('billed_amount', 'allowed_amount', 'paid_amount')
    def validate_amounts(cls, v):
        if v is not None and v < 0:
            raise ValueError('Amount cannot be negative')
        return v


class Provider(BaseModel):
    """Healthcare provider information"""
    provider_id: str = Field(..., description="Unique provider identifier")
    name: str = Field(..., description="Provider name")
    type: ProviderType = Field(..., description="Provider type")
    npi: str = Field(..., description="National Provider Identifier")
    tax_id: Optional[str] = Field(None, description="Tax identification number")
    address: Dict[str, str] = Field(..., description="Provider address")
    phone: Optional[str] = Field(None, description="Contact phone number")
    specialty: Optional[str] = Field(None, description="Medical specialty")


class Patient(BaseModel):
    """Patient information"""
    patient_id: str = Field(..., description="Unique patient identifier")
    member_id: str = Field(..., description="Insurance member ID")
    first_name: str = Field(..., description="Patient first name")
    last_name: str = Field(..., description="Patient last name")
    date_of_birth: datetime = Field(..., description="Patient date of birth")
    gender: str = Field(..., description="Patient gender")
    address: Dict[str, str] = Field(..., description="Patient address")
    phone: Optional[str] = Field(None, description="Contact phone number")
    
    @validator('gender')
    def validate_gender(cls, v):
        valid_genders = ['M', 'F', 'O', 'U']
        if v not in valid_genders:
            raise ValueError(f'Gender must be one of: {valid_genders}')
        return v


class Insurance(BaseModel):
    """Insurance information"""
    insurance_id: str = Field(..., description="Unique insurance identifier")
    payer_name: str = Field(..., description="Insurance company name")
    payer_id: str = Field(..., description="Payer identification number")
    group_number: str = Field(..., description="Group policy number")
    subscriber_number: str = Field(..., description="Subscriber number")
    plan_type: str = Field(..., description="Type of insurance plan")
    coverage_start_date: datetime = Field(..., description="Coverage start date")
    coverage_end_date: Optional[datetime] = Field(None, description="Coverage end date")


class MedicalClaim(BaseModel):
    """Complete medical claim record"""
    claim_id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="Unique claim identifier")
    claim_number: str = Field(..., description="Claim number from provider")
    claim_type: ClaimType = Field(..., description="Type of medical claim")
    claim_status: ClaimStatus = Field(default=ClaimStatus.SUBMITTED, description="Current claim status")
    
    # Core information
    patient: Patient = Field(..., description="Patient information")
    insurance: Insurance = Field(..., description="Insurance information")
    provider: Provider = Field(..., description="Billing provider")
    
    # Claim details
    claim_lines: List[ClaimLine] = Field(..., description="Individual claim line items")
    total_billed_amount: Decimal = Field(..., description="Total amount billed")
    total_allowed_amount: Optional[Decimal] = Field(None, description="Total amount allowed")
    total_paid_amount: Optional[Decimal] = Field(None, description="Total amount paid")
    patient_responsibility: Optional[Decimal] = Field(None, description="Patient's financial responsibility")
    
    # Dates
    date_of_service: datetime = Field(..., description="Date of service")
    claim_received_date: datetime = Field(default_factory=datetime.utcnow, description="Date claim was received")
    claim_processed_date: Optional[datetime] = Field(None, description="Date claim was processed")
    
    # Additional information
    notes: Optional[str] = Field(None, description="Additional claim notes")
    attachments: List[str] = Field(default_factory=list, description="List of attachment IDs")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional metadata")
    
    # Validation
    @validator('total_billed_amount', 'total_allowed_amount', 'total_paid_amount', 'patient_responsibility')
    def validate_total_amounts(cls, v):
        if v is not None and v < 0:
            raise ValueError('Total amount cannot be negative')
        return v
    
    @validator('claim_lines')
    def validate_claim_lines(cls, v):
        if not v:
            raise ValueError('Claim must have at least one line item')
        return v
    
    @validator('total_billed_amount')
    def validate_total_billed_matches_lines(cls, v, values):
        if 'claim_lines' in values:
            calculated_total = sum(line.billed_amount for line in values['claim_lines'])
            if abs(v - calculated_total) > Decimal('0.01'):
                raise ValueError('Total billed amount must match sum of line items')
        return v
    
    @property
    def claim_age_days(self) -> int:
        """Calculate the age of the claim in days"""
        return (datetime.utcnow() - self.claim_received_date).days
    
    @property
    def is_high_value(self) -> bool:
        """Check if this is a high-value claim (>$10,000)"""
        return self.total_billed_amount > Decimal('10000')
    
    @property
    def has_attachments(self) -> bool:
        """Check if claim has attachments"""
        return len(self.attachments) > 0
    
    def calculate_totals(self):
        """Recalculate totals from line items"""
        self.total_billed_amount = sum(line.billed_amount for line in self.claim_lines)
        if any(line.allowed_amount for line in self.claim_lines):
            self.total_allowed_amount = sum(line.allowed_amount or Decimal('0') for line in self.claim_lines)
        if any(line.paid_amount for line in self.claim_lines):
            self.total_paid_amount = sum(line.paid_amount or Decimal('0') for line in self.claim_lines)
        
        if self.total_allowed_amount and self.total_paid_amount:
            self.patient_responsibility = self.total_allowed_amount - self.total_paid_amount


class ClaimBatch(BaseModel):
    """Batch of medical claims for processing"""
    batch_id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="Unique batch identifier")
    batch_number: str = Field(..., description="Batch number")
    claims: List[MedicalClaim] = Field(..., description="Claims in this batch")
    batch_date: datetime = Field(default_factory=datetime.utcnow, description="Batch creation date")
    source_system: str = Field(..., description="Source system identifier")
    total_claims: int = Field(..., description="Total number of claims in batch")
    total_billed_amount: Decimal = Field(..., description="Total billed amount for batch")
    
    @validator('claims')
    def validate_claims(cls, v):
        if not v:
            raise ValueError('Batch must contain at least one claim')
        return v
    
    @validator('total_claims')
    def validate_total_claims(cls, v, values):
        if 'claims' in values and v != len(values['claims']):
            raise ValueError('Total claims count must match actual claims count')
        return v
    
    @validator('total_billed_amount')
    def validate_total_billed_amount(cls, v, values):
        if 'claims' in values:
            calculated_total = sum(claim.total_billed_amount for claim in values['claims'])
            if abs(v - calculated_total) > Decimal('0.01'):
                raise ValueError('Total billed amount must match sum of claim amounts')
        return v


class ClaimQualityMetrics(BaseModel):
    """Data quality metrics for claims"""
    claim_id: str = Field(..., description="Claim identifier")
    completeness_score: float = Field(..., ge=0, le=100, description="Data completeness score (0-100)")
    accuracy_score: float = Field(..., ge=0, le=100, description="Data accuracy score (0-100)")
    validity_score: float = Field(..., ge=0, le=100, description="Data validity score (0-100)")
    overall_score: float = Field(..., ge=0, le=100, description="Overall quality score (0-100)")
    
    missing_fields: List[str] = Field(default_factory=list, description="List of missing required fields")
    validation_errors: List[str] = Field(default_factory=list, description="List of validation errors")
    data_anomalies: List[str] = Field(default_factory=list, description="List of detected data anomalies")
    
    created_at: datetime = Field(default_factory=datetime.utcnow, description="Metrics creation timestamp")
    
    @validator('overall_score')
    def calculate_overall_score(cls, v, values):
        if 'completeness_score' in values and 'accuracy_score' in values and 'validity_score' in values:
            calculated = (values['completeness_score'] + values['accuracy_score'] + values['validity_score']) / 3
            if abs(v - calculated) > 0.01:
                raise ValueError('Overall score must be average of individual scores')
        return v

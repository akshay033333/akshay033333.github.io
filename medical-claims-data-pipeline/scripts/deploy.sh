#!/bin/bash

# Medical Claims Data Pipeline Deployment Script
# This script handles deployment to different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
ENVIRONMENT="dev"
ACTION="deploy"
DRY_RUN=false
FORCE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option $1"
            show_help
            exit 1
            ;;
    esac
done

# Show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV    Environment to deploy to (dev, staging, prod)"
    echo "  -a, --action ACTION      Action to perform (deploy, destroy, plan, validate)"
    echo "  --dry-run                Show what would be deployed without actually deploying"
    echo "  --force                  Force deployment even if there are warnings"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e dev -a deploy     # Deploy to development environment"
    echo "  $0 -e staging -a plan   # Show deployment plan for staging"
    echo "  $0 -e prod -a destroy   # Destroy production environment"
}

# Validate environment
validate_environment() {
    case $ENVIRONMENT in
        dev|staging|prod)
            print_status "Environment: $ENVIRONMENT"
            ;;
        *)
            print_error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod"
            exit 1
            ;;
    esac
}

# Validate action
validate_action() {
    case $ACTION in
        deploy|destroy|plan|validate|apply|refresh)
            print_status "Action: $ACTION"
            ;;
        *)
            print_error "Invalid action: $ACTION"
            exit 1
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ] || [ ! -d "infrastructure" ]; then
        print_error "Must run from project root directory"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    
    # Check AWS CLI (for cloud deployment)
    if [ "$ENVIRONMENT" != "dev" ] && ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed (required for cloud deployment)"
        exit 1
    fi
    
    print_success "Prerequisites check completed"
}

# Deploy local environment
deploy_local() {
    print_status "Deploying local environment..."
    
    if [ "$DRY_RUN" = true ]; then
        print_status "DRY RUN: Would start local services"
        return
    fi
    
    # Stop existing services
    docker-compose down --remove-orphans
    
    # Start services
    docker-compose up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    check_service_health
    
    print_success "Local environment deployed successfully"
}

# Deploy cloud environment
deploy_cloud() {
    print_status "Deploying to cloud environment: $ENVIRONMENT"
    
    cd "infrastructure/environments/$ENVIRONMENT"
    
    # Initialize Terraform
    if [ ! -d ".terraform" ]; then
        print_status "Initializing Terraform..."
        terraform init
    fi
    
    # Validate configuration
    print_status "Validating Terraform configuration..."
    terraform validate
    
    # Show plan
    if [ "$ACTION" = "plan" ] || [ "$DRY_RUN" = true ]; then
        print_status "Showing deployment plan..."
        terraform plan
        return
    fi
    
    # Apply changes
    if [ "$ACTION" = "deploy" ] || [ "$ACTION" = "apply" ]; then
        print_status "Applying Terraform configuration..."
        
        if [ "$FORCE" = true ]; then
            terraform apply -auto-approve
        else
            terraform apply
        fi
        
        print_success "Cloud environment deployed successfully"
    fi
    
    # Destroy environment
    if [ "$ACTION" = "destroy" ]; then
        print_status "Destroying cloud environment..."
        
        if [ "$FORCE" = true ]; then
            terraform destroy -auto-approve
        else
            terraform destroy
        fi
        
        print_success "Cloud environment destroyed successfully"
    fi
    
    cd ../../..
}

# Check service health
check_service_health() {
    print_status "Checking service health..."
    
    local services=(
        "kafka:8080"
        "spark:8081"
        "minio:9001"
        "postgres:5432"
        "prometheus:9090"
        "grafana:3000"
    )
    
    for service in "${services[@]}"; do
        local name=$(echo $service | cut -d: -f1)
        local port=$(echo $service | cut -d: -f2)
        
        if curl -s "http://localhost:$port" > /dev/null 2>&1; then
            print_success "$name is running on port $port"
        else
            print_warning "$name is not accessible on port $port"
        fi
    done
}

# Deploy application code
deploy_application() {
    print_status "Deploying application code..."
    
    if [ "$DRY_RUN" = true ]; then
        print_status "DRY RUN: Would deploy application code"
        return
    fi
    
    # Create necessary directories
    mkdir -p logs
    mkdir -p data/processed
    mkdir -p checkpoints
    
    # Set permissions
    chmod +x scripts/*.sh
    
    # Install Python dependencies
    if [ -f "requirements.txt" ]; then
        print_status "Installing Python dependencies..."
        pip install -r requirements.txt
    fi
    
    print_success "Application code deployed successfully"
}

# Run tests
run_tests() {
    print_status "Running tests..."
    
    if [ "$DRY_RUN" = true ]; then
        print_status "DRY RUN: Would run tests"
        return
    fi
    
    # Run Python tests
    if [ -d "src/tests" ]; then
        python -m pytest src/tests/ -v
    else
        print_warning "No tests directory found"
    fi
    
    print_success "Tests completed"
}

# Main deployment function
main() {
    echo "🏥 Medical Claims Data Pipeline Deployment"
    echo "=========================================="
    echo ""
    
    # Validate inputs
    validate_environment
    validate_action
    
    # Check prerequisites
    check_prerequisites
    
    # Deploy based on environment
    if [ "$ENVIRONMENT" = "dev" ]; then
        deploy_local
    else
        deploy_cloud
    fi
    
    # Deploy application code
    deploy_application
    
    # Run tests if deploying
    if [ "$ACTION" = "deploy" ] || [ "$ACTION" = "apply" ]; then
        run_tests
    fi
    
    # Display deployment summary
    display_deployment_summary
}

# Display deployment summary
display_deployment_summary() {
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Summary:"
    echo "- Environment: $ENVIRONMENT"
    echo "- Action: $ACTION"
    echo "- Dry Run: $DRY_RUN"
    echo ""
    
    if [ "$ENVIRONMENT" = "dev" ]; then
        echo "🌐 Local Services:"
        echo "- Kafka UI: http://localhost:8080"
        echo "- Spark Master: http://localhost:8081"
        echo "- MinIO Console: http://localhost:9001"
        echo "- Grafana: http://localhost:3000"
        echo "- Prometheus: http://localhost:9090"
        echo ""
        echo "🛠️  Next Steps:"
        echo "1. Activate virtual environment: source venv/bin/activate"
        echo "2. Start data producer: python src/producers/mock_data_generator.py"
        echo "3. Start streaming processor: python src/processors/streaming_processor.py"
        echo "4. Monitor services: docker-compose logs -f"
    else
        echo "☁️  Cloud Environment:"
        echo "- Check AWS console for deployed resources"
        echo "- Review Terraform outputs for connection details"
        echo ""
        echo "🛠️  Next Steps:"
        echo "1. Configure monitoring and alerting"
        echo "2. Set up CI/CD pipeline"
        echo "3. Configure backup and disaster recovery"
        echo "4. Run performance tests"
    fi
    
    echo ""
    echo "📚 Useful Commands:"
    echo "- View logs: docker-compose logs -f [service]"
    echo "- Stop services: docker-compose down"
    echo "- Restart services: docker-compose restart"
    echo "- Check status: docker-compose ps"
    echo ""
}

# Run main function
main "$@"

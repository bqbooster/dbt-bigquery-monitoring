#!/usr/bin/env python3
"""
Cleanup script for test datasets created during CI/CD runs.
This script identifies and deletes BigQuery datasets matching the pattern:
dbt_bigquery_monitoring_test_commit_*
"""

import argparse
import logging
import sys
from typing import List

from google.cloud import bigquery
from google.api_core import exceptions

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def list_test_datasets(client: bigquery.Client, project_id: str, pattern: str = "dbt_bigquery_monitoring_test_commit_") -> List[str]:
    """
    List all datasets matching the test dataset pattern.
    
    Args:
        client: BigQuery client instance
        project_id: GCP project ID
        pattern: Dataset name pattern to match
        
    Returns:
        List of dataset IDs matching the pattern
    """
    logger.info(f"Searching for datasets matching pattern '{pattern}*' in project '{project_id}'")
    
    try:
        datasets = list(client.list_datasets(project=project_id))
        test_datasets = [
            dataset.dataset_id 
            for dataset in datasets 
            if dataset.dataset_id.startswith(pattern)
        ]
        
        logger.info(f"Found {len(test_datasets)} test datasets")
        return test_datasets
    except exceptions.GoogleAPIError as e:
        logger.error(f"Error listing datasets: {e}")
        raise


def delete_dataset(client: bigquery.Client, project_id: str, dataset_id: str, dry_run: bool = False) -> bool:
    """
    Delete a BigQuery dataset and all its contents.
    
    Args:
        client: BigQuery client instance
        project_id: GCP project ID
        dataset_id: Dataset ID to delete
        dry_run: If True, only log what would be deleted without actually deleting
        
    Returns:
        True if deletion was successful (or would be in dry-run mode), False otherwise
    """
    dataset_ref = f"{project_id}.{dataset_id}"
    
    if dry_run:
        logger.info(f"[DRY RUN] Would delete dataset: {dataset_ref}")
        return True
    
    try:
        # Delete dataset with all tables/views (delete_contents=True)
        logger.info(f"Deleting dataset: {dataset_ref}")
        client.delete_dataset(
            dataset_ref,
            delete_contents=True,  # This deletes all tables and views in the dataset
            not_found_ok=False
        )
        logger.info(f"Successfully deleted dataset: {dataset_ref}")
        return True
    except exceptions.NotFound:
        logger.warning(f"Dataset not found: {dataset_ref}")
        return False
    except exceptions.GoogleAPIError as e:
        logger.error(f"Error deleting dataset {dataset_ref}: {e}")
        return False


def cleanup_test_datasets(
    project_id: str,
    pattern: str = "dbt_bigquery_monitoring_test_commit_",
    dry_run: bool = False,
    max_datasets: int = None
) -> int:
    """
    Main cleanup function to identify and delete test datasets.
    
    Args:
        project_id: GCP project ID
        pattern: Dataset name pattern to match
        dry_run: If True, only log what would be deleted
        max_datasets: Maximum number of datasets to delete (None for unlimited)
        
    Returns:
        Number of datasets successfully deleted
    """
    logger.info("Starting test dataset cleanup")
    logger.info(f"Project: {project_id}")
    logger.info(f"Pattern: {pattern}*")
    logger.info(f"Dry run: {dry_run}")
    
    # Initialize BigQuery client
    client = bigquery.Client(project=project_id)
    
    # List test datasets
    test_datasets = list_test_datasets(client, project_id, pattern)
    
    if not test_datasets:
        logger.info("No test datasets found to clean up")
        return 0
    
    # Apply max_datasets limit if specified
    if max_datasets and len(test_datasets) > max_datasets:
        logger.info(f"Limiting cleanup to {max_datasets} datasets (found {len(test_datasets)})")
        test_datasets = test_datasets[:max_datasets]
    
    # Delete datasets
    deleted_count = 0
    failed_count = 0
    
    for dataset_id in test_datasets:
        if delete_dataset(client, project_id, dataset_id, dry_run):
            deleted_count += 1
        else:
            failed_count += 1
    
    # Summary
    logger.info("=" * 60)
    logger.info("Cleanup Summary:")
    logger.info(f"  Total datasets found: {len(test_datasets)}")
    logger.info(f"  Successfully deleted: {deleted_count}")
    logger.info(f"  Failed: {failed_count}")
    logger.info("=" * 60)
    
    return deleted_count


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="Cleanup test datasets from BigQuery",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Dry run to see what would be deleted
  python cleanup_test_datasets.py --project my-project --dry-run
  
  # Actually delete test datasets
  python cleanup_test_datasets.py --project my-project
  
  # Delete with custom pattern
  python cleanup_test_datasets.py --project my-project --pattern my_test_
  
  # Limit to 10 datasets
  python cleanup_test_datasets.py --project my-project --max-datasets 10
        """
    )
    
    parser.add_argument(
        "--project",
        required=True,
        help="GCP project ID containing the datasets"
    )
    parser.add_argument(
        "--pattern",
        default="dbt_bigquery_monitoring_test_commit_",
        help="Dataset name pattern to match (default: dbt_bigquery_monitoring_test_commit_)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Perform a dry run without actually deleting datasets"
    )
    parser.add_argument(
        "--max-datasets",
        type=int,
        default=None,
        help="Maximum number of datasets to delete (default: unlimited)"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging"
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    try:
        deleted_count = cleanup_test_datasets(
            project_id=args.project,
            pattern=args.pattern,
            dry_run=args.dry_run,
            max_datasets=args.max_datasets
        )
        
        if args.dry_run:
            logger.info("Dry run completed successfully")
            sys.exit(0)
        elif deleted_count > 0:
            logger.info(f"Cleanup completed successfully. Deleted {deleted_count} datasets.")
            sys.exit(0)
        else:
            logger.info("No datasets were deleted")
            sys.exit(0)
            
    except Exception as e:
        logger.error(f"Cleanup failed with error: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()

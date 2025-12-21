# Test Dataset Cleanup

This directory contains scripts for managing and cleaning up test datasets created during CI/CD runs.

## Overview

During integration tests, dbt creates temporary BigQuery datasets with the naming pattern:
```
dbt_bigquery_monitoring_test_commit_<commit_hash>
```

These datasets should be cleaned up after testing to avoid accumulating storage costs and clutter.

## Automated Cleanup

A GitHub workflow (`.github/workflows/cleanup_test_datasets.yml`) runs automatically:
- **Schedule**: Daily at 2:00 AM UTC
- **Manual trigger**: Can be triggered manually from the GitHub Actions UI

### Manual Workflow Trigger

You can manually trigger the cleanup workflow from GitHub:

1. Go to the **Actions** tab in the repository
2. Select **Cleanup Test Datasets** workflow
3. Click **Run workflow**
4. Configure options:
   - **Dry run**: Check this to see what would be deleted without actually deleting
   - **Max datasets**: Optionally limit the number of datasets to delete

## Manual Cleanup

You can also run the cleanup script manually:

### Prerequisites

```bash
pip install google-cloud-bigquery
```

### Usage

```bash
# Dry run to see what would be deleted
python scripts/cleanup_test_datasets.py \
  --project YOUR_PROJECT_ID \
  --dry-run

# Actually delete test datasets
python scripts/cleanup_test_datasets.py \
  --project YOUR_PROJECT_ID

# Delete with a limit
python scripts/cleanup_test_datasets.py \
  --project YOUR_PROJECT_ID \
  --max-datasets 10

# Use custom pattern
python scripts/cleanup_test_datasets.py \
  --project YOUR_PROJECT_ID \
  --pattern my_custom_test_prefix_
```

### Authentication

The script uses Google Cloud authentication. Make sure you have one of:
- `GOOGLE_APPLICATION_CREDENTIALS` environment variable pointing to a service account key
- Default application credentials configured via `gcloud auth application-default login`

### Options

- `--project`: (Required) GCP project ID containing the datasets
- `--pattern`: Dataset name pattern to match (default: `dbt_bigquery_monitoring_test_commit_`)
- `--dry-run`: Perform a dry run without actually deleting datasets
- `--max-datasets`: Maximum number of datasets to delete (default: unlimited)
- `--verbose`: Enable verbose logging

## How It Works

The cleanup script:

1. **Lists datasets**: Queries BigQuery to find all datasets matching the pattern
2. **Deletes datasets**: For each matching dataset:
   - Automatically deletes all tables and views within the dataset
   - Deletes the dataset itself
3. **Reports results**: Provides a summary of deleted and failed deletions

### BigQuery Dataset Deletion

The script uses `delete_contents=True` when deleting datasets, which:
- Automatically removes all tables, views, and other objects in the dataset
- Eliminates the need to manually drop tables/views before dropping the dataset
- Handles the cleanup in a single API call per dataset

## Troubleshooting

### Permission Errors

If you encounter permission errors, ensure the service account has:
- `bigquery.datasets.delete` permission
- `bigquery.tables.delete` permission

These are typically included in the `BigQuery Admin` role.

### Rate Limiting

If you have many datasets to delete, you might hit API rate limits. Use `--max-datasets` to limit the number of deletions per run.

## Safety Features

- **Dry run mode**: Always test with `--dry-run` first
- **Pattern matching**: Only deletes datasets matching the specific pattern
- **Detailed logging**: All operations are logged for audit purposes
- **Error handling**: Failed deletions are logged but don't stop the cleanup process

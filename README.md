# lite-data-stack-postgres

A Lite Data Stack template powered by Meltano (extraction) and dbt (transformation) with PostgreSQL storage, preconfigured to ingest the Rick and Morty API end to end.

## Quick Start

### Prerequisites

- Python 3.11+
- PostgreSQL database
- Git
- uv (Python package manager)

### Environment Variables

Create a `.env` file in the root directory (or start from `.env.example`):

```bash
# Database Configuration (for PostgreSQL)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=your_database
DB_USER=your_username
DB_PASSWORD=your_password
DBT_USER=yourname
```

### Setup

1. **Set up Extraction (Meltano)**:

   ```bash
   cd extraction
   ./scripts/setup-local.sh
   ```

   This script will:
   - Check Python version (>=3.11)
   - Create a virtual environment
   - Install uv and dependencies via `pyproject.toml`
   - Initialize Meltano

2. **Set up Transform (dbt)**:

   ```bash
   cd transform
   ./scripts/setup-local.sh
   ```

   This script will:
   - Check Python version (>=3.11)
   - Create a virtual environment
   - Install uv and dependencies via `pyproject.toml`

3. **Configure dbt**:

   ```bash
   cd transform
   cp profiles.yml.example profiles.yml
   # Edit profiles.yml with your database credentials
   ```

4. **Set DBT_USER for development (if not set in `.env`)**:

   ```bash
   export DBT_USER="yourname"
   ```

### Running

1. **Review the extractor setup** in `extraction/meltano.yml`:
   - `tap-rickandmorty` pulls from the public API
   - `target-postgres` loads into the `raw` schema

2. **Run Extraction**:

   ```bash
   cd extraction
   meltano run tap-rickandmorty target-postgres
   ```

3. **Run Transformation**:

   ```bash
   cd transform
   dbt deps
   dbt run
   dbt test
   ```

## Project Structure

```
lite-data-stack-postgres/
├── extraction/                  # Meltano project for data extraction
│   ├── meltano.yml              # Rick & Morty tap + Postgres target
│   ├── scripts/
│   │   └── setup-local.sh       # Helper script for setup
│   └── venv/                    # Python virtual environment
├── transform/                   # dbt project for data transformation
│   ├── dbt_project.yml          # dbt configuration
│   ├── packages.yml             # dbt packages
│   ├── profiles.yml.example     # Database profiles template
│   ├── macros/
│   │   └── generate_schema_name.sql  # Schema naming with sandbox support
│   ├── models/
│   │   ├── staging/             # Staging models
│   │   └── production/
│   │       └── marts/           # Production models
│   ├── scripts/
│   │   └── setup-local.sh       # Helper script for setup
│   ├── seeds/                   # Seed data
│   ├── analyses/                # Analysis queries
│   ├── snapshots/               # Snapshots
│   └── tests/                   # Tests
├── .github/
│   └── workflows/
│       └── data-pipeline.yml    # End-to-end ETL workflow
├── .env.example                 # Environment variable template
├── pyproject.toml               # Python dependencies with uv support
└── README.md
```

## Configuration

### Extraction (Meltano)

This template already includes:

- `tap-rickandmorty` as the extractor
- `target-postgres` as the loader
- A daily schedule for the pipeline

### Transform (dbt)

#### Environments

- **Prod**: Uses configured schema names
- **Dev**: Uses sandbox datasets (`SANDBOX_<USER>`)
- **CI**: Uses sandbox datasets with a run identifier (`SANDBOX_CI_PR_<NUMBER>`)

#### Sandbox Strategy

The project uses sandbox datasets for development and CI:

- **Local development**: Each developer gets `SANDBOX_<USER>` dataset
- **PR CI**: Each PR gets `SANDBOX_CI_PR_<NUMBER>` dataset
- **Prod**: Direct schema access with `persist_docs` enabled

#### Defer Support

When running with `--defer` flag, dbt will use production datasets for unmodified models:

```bash
dbt build --defer --state prod-artifacts --select state:modified+
```

## CI/CD

### Workflows

1. **Data Pipeline** (`.github/workflows/data-pipeline.yml`)
   - Scheduled runs (configurable cron)
   - Manual dispatch
   - Runs extraction followed by transformation

### Setting Up CI/CD

You'll need to configure database credentials if you point the workflow at an external Postgres instance. The default workflow uses the built-in Postgres service.

## Development

### Local Development

1. Install dependencies via setup scripts
2. Set `DBT_USER` environment variable
3. Work in your sandbox dataset: `SANDBOX_<USER>`
4. Test changes before committing

### Using Defer

To test changes against production data:

```bash
# Download production manifest
# (automatically done in CI/CD)

# Run with defer
dbt build --defer --state prod-artifacts --select state:modified+
```

### Best Practices

- Always run in sandbox datasets for development
- Use `--defer` to test against production data
- Test in PR before merging to main
- Keep staging models as views for easy iteration
- Document models with `persist_docs` enabled

## Testing

### Test Extraction

```bash
cd extraction
meltano test
```

### Test Transform

```bash
cd transform
dbt test
dbt run
```

## Troubleshooting

### DBT_USER not set

For development mode, ensure `DBT_USER` is set:

```bash
export DBT_USER="yourname"
```

### Sandbox dataset issues

If sandbox dataset doesn't exist:

- Local: Check database permissions
- CI: Check cloud provider authentication

### Defer not working

Ensure:

- Production manifest is downloaded
- State directory is correctly specified
- `--defer` flag is used

## Resources

- [Meltano Documentation](https://docs.meltano.com/)
- [dbt Documentation](https://docs.getdbt.com/)
- [PostgreSQL Documentation](https://www.postgres.com/docs)
- [uv Documentation](https://github.com/astral-sh/uv)

## Contributing

1. Create a feature branch
2. Make your changes
3. Test in your sandbox dataset
4. Submit a pull request
5. CI will run in PR-specific sandbox dataset

## License

MIT

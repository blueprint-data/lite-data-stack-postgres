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
# Database Configuration (PostgreSQL)
# Use the host only (no https:// or postgresql://)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=your_database
DB_USER=your_username
DB_PASSWORD=your_password
DB_SSLMODE=require

# Used to name dev schemas: SANDBOX_<USER>
DBT_USER=yourname

# Meltano loader (target-postgres)
# These can mirror DB_* or be set in extraction/.env
TARGET_POSTGRES_HOST=localhost
TARGET_POSTGRES_PORT=5432
TARGET_POSTGRES_DATABASE=your_database
TARGET_POSTGRES_USER=your_username
TARGET_POSTGRES_PASSWORD=your_password
```

Supabase users: use the values from Settings → Database → Connection string.
Session pooler uses port 5432, and Transaction pooler uses port 6543.
If you use the Transaction pooler, your host/port/user will look like:

```bash
DB_HOST=aws-1-us-east-1.pooler.supabase.com
DB_PORT=6543
DB_USER=postgres.<project-ref>
```

For local extraction, you can copy `extraction/.env.example` to `extraction/.env` and load it with:

```bash
cd extraction
set -a; source .env; set +a
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
   ```

4. **Set DBT_USER for development (if not set in `.env`)**:

   ```bash
   export DBT_USER="yourname"
   ```

### Running

1. **Load environment variables**:

   ```bash
   set -a; source .env; set +a
   ```

2. **Review the extractor setup** in `extraction/meltano.yml`:
   - `tap-rest-rickandmorty` pulls from the public API
   - `target-postgres` loads into `${MELTANO_ENVIRONMENT}_${MELTANO_EXTRACTOR_NAMESPACE}`
     (for example: `dev_tap_rest_rickandmorty`, `prod_tap_rest_rickandmorty`)

3. **Run Extraction**:

   ```bash
   cd extraction
   set -a; source .env; set +a
   ./scripts/setup-local.sh
   source venv/bin/activate 
   meltano run tap-rest-rickandmorty target-postgres
   ```
   To run against prod schemas:

   ```bash
   meltano --environment=prod run tap-rest-rickandmorty target-postgres
   ```

4. **Run Transformation (dev)**:

   ```bash
   cd transform
   ./scripts/setup-local.sh
   source venv/bin/activate 
   dbt deps
   dbt run
   dbt test
   ```

5. **Run Transformation (prod schemas)**:

   ```bash
   dbt run --target prod
   dbt test --target prod
   ```

### Docs

Generate and serve dbt docs for the active target:

```bash
dbt docs generate
dbt docs serve
```

For prod schemas:

```bash
dbt docs generate --target prod
dbt docs serve --target prod
```

## Project Structure

```
lite-data-stack-postgres/
├── extraction/                  # Meltano project for data extraction
│   ├── meltano.yml              # Rick & Morty REST tap + Postgres target
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

- `tap-rest-rickandmorty` as the extractor
- `target-postgres` as the loader
- Loads data into `${MELTANO_ENVIRONMENT}_${MELTANO_EXTRACTOR_NAMESPACE}`

### Transform (dbt)

#### Environments

- **Prod/CI**: Uses configured schema names (`stg`, `marts`; `int` if added)
- **Dev**: Uses sandbox schemas (`SANDBOX_<USER>`)

#### Sandbox Strategy

The project uses sandbox schemas for development:

- **Local development**: Each developer gets `SANDBOX_<USER>` schema
- **Prod**: Direct schema access with `persist_docs` enabled

#### Defer Support

When running with `--defer` flag, dbt will use production schemas for unmodified models:

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

The workflow expects an external Postgres instance and reads credentials from GitHub Actions secrets:

- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `DBT_USER` (used for sandbox schema naming in dev targets)
- `DB_SSLMODE` (for example: `require` for Supabase)

The workflow maps these `DB_*` secrets into the `TARGET_POSTGRES_*` variables that Meltano uses.

If your database restricts inbound connections, allow GitHub Actions runner IPs for the region or use a publicly reachable endpoint.

## Development

### Local Development

1. Install dependencies via setup scripts
2. Set `DBT_USER` environment variable
3. Work in your sandbox schema: `SANDBOX_<USER>`
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

- Always run in sandbox schemas for development
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

### Meltano target-postgres config missing

If you see "Required key is missing from config", ensure `TARGET_POSTGRES_*` are set or load `extraction/.env` before running Meltano.

## Troubleshooting

### DBT_USER not set

For development mode, ensure `DBT_USER` is set:

```bash
export DBT_USER="yourname"
```

### Sandbox schema issues

If the sandbox schema doesn't exist:

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
3. Test in your sandbox schema
4. Submit a pull request
5. Run the pipeline end to end before merging

## License

MIT

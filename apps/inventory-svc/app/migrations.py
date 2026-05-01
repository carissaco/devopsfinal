"""Tiny migration runner. Reads V*.sql files in order, tracks them in a
schema_migrations table, applies any not yet applied. Each file runs in its own
transaction. Filename pattern: V<n>__<description>.sql"""

import logging
import re
from pathlib import Path

import asyncpg

log = logging.getLogger(__name__)
MIGRATIONS_DIR = Path(__file__).parent.parent / "migrations"
FILENAME_RE = re.compile(r"^V(\d+)__(.+)\.sql$")


async def run(conn: asyncpg.Connection, schema: str) -> None:
    await conn.execute(f'CREATE SCHEMA IF NOT EXISTS "{schema}"')
    await conn.execute(f'SET search_path TO "{schema}"')
    await conn.execute(
        """
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version    INTEGER PRIMARY KEY,
            name       TEXT NOT NULL,
            applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )
        """
    )

    applied = {row["version"] for row in await conn.fetch("SELECT version FROM schema_migrations")}

    files = sorted(MIGRATIONS_DIR.glob("V*.sql"))
    for path in files:
        m = FILENAME_RE.match(path.name)
        if not m:
            log.warning("skipping malformed migration filename: %s", path.name)
            continue
        version = int(m.group(1))
        if version in applied:
            continue
        sql = path.read_text(encoding="utf-8")
        log.info("applying migration V%d (%s)", version, m.group(2))
        async with conn.transaction():
            await conn.execute(sql)
            await conn.execute(
                "INSERT INTO schema_migrations (version, name) VALUES ($1, $2)",
                version,
                m.group(2),
            )

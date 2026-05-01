"""Tiny migration runner — same approach as inventory-svc."""

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
    for path in sorted(MIGRATIONS_DIR.glob("V*.sql")):
        m = FILENAME_RE.match(path.name)
        if not m:
            continue
        version = int(m.group(1))
        if version in applied:
            continue
        log.info("applying migration V%d (%s)", version, m.group(2))
        async with conn.transaction():
            await conn.execute(path.read_text(encoding="utf-8"))
            await conn.execute(
                "INSERT INTO schema_migrations (version, name) VALUES ($1, $2)",
                version,
                m.group(2),
            )

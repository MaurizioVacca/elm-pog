import {Pool} from 'pg';
import 'dotenv/config';

const LINE_WIDTH = 72;

const formatTitle = (title: string)=> {
    const dashes = "-".repeat(LINE_WIDTH - title.length - 4);
    return `-- ${title} ${dashes}`;
}

const formatError = ({title, body, hint})=> {
    const parts = [formatTitle(title), "", body];
    if (hint) parts.push("", `Hint: ${hint}`);
    return parts.join("\n");
}

const classifyError = (err: { code: string; message: string })=> {
    const code = err.code ?? "";
    const message = err.message ?? "An unknown database error occurred.";

    switch (code) {
        case "ECONNREFUSED":
        case "ENOTFOUND":
            return {
                kind: "fatal",
                message: formatError({
                    title: "DATABASE CONNECTION FAILED",
                    body: `I could not connect to the database.\n\n    ${message}`,
                    hint: "Check that your DATABASE_URL or PG* environment variables are set correctly, and that the database server is running.",
                }),
            };
        case "EPOOLUNDEFINED":
            return {
                kind: "fatal",
                message: formatError({
                    title: "POOL UNDEFINED",
                    body: `I could not create a new pool.\n\n    ${message}`,
                    hint: "This is generally caused by a misconfiguration on your custom-backend-task.ts.",
                }),
            }
        case "42601":
        case "42P01":
            return {
                kind: "fatal",
                message: formatError({
                    title: "INVALID QUERY",
                    body: `The query was rejected by the database.\n\n    ${message}`,
                    hint: "This is likely a bug in the query builder output. Check the generated SQL by logging the query before execution.",
                }),
            };
        case "53300":
            return {
                kind: "fatal",
                message: formatError({
                    title: "CONNECTION POOL EXHAUSTED",
                    body: "All database connections are in use and no new connections could be created.",
                    hint: "Reduce the number of concurrent requests or increase the pool `max` setting when calling new pg.Pool(...).",
                }),
            };
        default:
            // Fallback for any unclassified error — still formatted but generic.
            return {
                kind: "fatal",
                message: formatError({
                    title: "DATABASE ERROR",
                    body: `An unexpected database error occurred.\n\n    ${message}`,
                    hint: "If this error persists, check your database server logs for more detail.",
                }),
            };
    }
}

type Params = number | string | boolean | null;

type Query = {
    sql: string;
    params: Params[];
}

let pool: Pool | null = null;

const getPool = () => {
    if (!pool) {
        pool = new Pool({
            database: process.env.PGDATABASE,
            host: process.env.PGHOST,
            port: Number(process.env.PGPORT),
            user: process.env.PGUSER,
        });
    }
    return pool;
};

const dbQuery = async ({sql, params}: Query) => {
    const pool = getPool();

    try {
        const result = await pool.query(sql, params);

        return ({ rows: result.rows });
    } catch (err) {
        const classified = classifyError(err);

        throw new Error(classified.message);
    }
}

export { dbQuery, Query };
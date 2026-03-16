import {dbQuery, startPool} from "./ElmPog/elm-pog";

export async function hello(name) {
  return `Hello ${name}!`;
}

const pool =  startPool();

export const executeQuery = (query) => dbQuery(pool, query);
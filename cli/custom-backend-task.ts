import { dbQuery, Query } from '../ElmPog/elm-pog';

export async function executeQuery (query: Query) {
  return await dbQuery(query);
}
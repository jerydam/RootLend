import { sql } from '@vercel/postgres';

export default async function handler(req, res) {
  try {
    const { loanid } = req.body;
    const query = 'SELECT * FROM rootlendchat WHERE loanid = $1';
    const values = [loanid];
   
    //Process the query
    const data = await sql.query(query, values);

    res.status(200).json(data.rows); // Extract rows
    console.log(data.rows); 
  } catch (error) {
    console.error('Error retrieving chat data:', error);
    res.status(500).json({ error: 'Error retrieving chat data' });
  }
}



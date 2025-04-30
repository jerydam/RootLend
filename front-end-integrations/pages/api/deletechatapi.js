import { sql } from '@vercel/postgres';

export default async function handler(req, res) {

  try {
    const {loanid} = req.body;
    const query = 'DELETE FROM rootlendchat WHERE loanid=$1';
    const values = [loanid];

    await sql.query(query, values);

    res.status(200).json({ message: 'chat deleted successfully' });
    console.log("chat deleted successfully")
  } catch (error) {
    console.error('Error deleting chat data:', error);
    res.status(500).json({ error: 'Error deleting chat data' });
  } 
}


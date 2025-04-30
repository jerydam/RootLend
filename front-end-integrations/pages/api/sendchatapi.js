import { sql } from '@vercel/postgres';

export default async function handler(req, res) {

  try {
    const { message, lender, borrower, sender, loanid, datetime } = req.body;
    const query = 'INSERT INTO rootlendchat (message, lender, borrower, sender, loanid, datetime) VALUES ($1, $2, $3, $4, $5, $6)';
    const values = [message, lender, borrower, sender, loanid, datetime];

    await sql.query(query, values);

    res.status(200).json({ message: 'chat added successfully' });
    console.log("chat added successfully")
  } catch (error) {
    console.error('Error adding chat:', error);
    res.status(500).json({ error: 'Error adding chat' });
  } 
}


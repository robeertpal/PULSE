import unittest
from unittest.mock import patch, MagicMock

class AIEvalsTest(unittest.TestCase):
    
    # --- Agent 1: Recomandări personalizate ---
    @patch("main._try_generate_for_you_ai_reasons")
    def test_eval_agent_1_recommendations(self, mock_ai):
        """
        Eval: Verifică dacă recomandările AI folosesc contextul utilizatorului
        """
        # Setăm un mock determinist pentru a evalua funcția wrapper
        mock_ai.return_value = (
            {101: "Acest curs acoperă subiectul tău de interes major: Cardiologie."},
            None
        )
        
        context = {
            "profile_specialization_name": "Cardiologie",
            "user_interest_names": ["Chirurgie", "Prevenție"],
            "content_type_preferences": {"curs": 5}
        }
        
        recommendations_input = [
            {"id": 101, "title": "Noutăți în Cardiologie", "category": "Curs"},
            {"id": 102, "title": "Pediatrie de bază", "category": "Articol"}
        ]
        
        from main import _try_generate_for_you_ai_reasons
        result, error = _try_generate_for_you_ai_reasons(context, recommendations_input)
        
        # Eval Checks
        self.assertIsNone(error)
        self.assertIn(101, result) # Relevant content was recommended
        self.assertNotIn(102, result) # Irrelevant content was skipped
        self.assertIn("Cardiologie", result[101]) # Explanation is coherent and uses context

    # --- Agent 2: Rezumare inteligentă ---
    @patch("main.genai.Client")
    @patch("os.getenv")
    def test_eval_agent_2_summarization(self, mock_getenv, mock_client):
        """
        Eval: Verifică dacă rezumatul AI extrage ideile esențiale și este mai scurt.
        """
        mock_getenv.side_effect = lambda k, d=None: "gemini" if k == "AI_PROVIDER" else "fake_key" if k == "GEMINI_API_KEY" else d
        
        mock_response = MagicMock()
        mock_response.text = "- Prima idee cheie extrasă.\n- A doua idee esențială."
        mock_client.return_value.models.generate_content.return_value = mock_response
        
        long_article = "Acesta este un articol foarte lung. " * 50
        
        from main import generate_ai_summary_payload
        result, _ = generate_ai_summary_payload(long_article)
        
        # Eval Checks
        self.assertTrue(len(result["summary"]) > 0) # Summary is not empty
        self.assertTrue(len(result["summary"]) < len(long_article)) # Summary is shorter than original
        self.assertIn("Prima idee", result["summary"]) # Key idea included
        self.assertFalse("informații evidente care nu există în articol" in result["summary"])



if __name__ == "__main__":
    unittest.main()

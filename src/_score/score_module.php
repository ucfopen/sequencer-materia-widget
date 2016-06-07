<?php
/**
 * Materia
 * It's a thing
 *
 * @package	    Materia
 * @version    1.0
 * @author     UCF New Media
 * @copyright  2011 New Media
 * @link       http://kogneato.com
 */


/**
 * NEEDS DOCUMENTATION
 *
 * The widget managers for the Materia package.
 *
 * @package	    Main
 * @subpackage  scoring
 * @category    Modules
  * @author      ADD NAME HERE
 */

namespace Materia;

class Score_Modules_Sequencer extends Score_Module
{
	const ATTEMPT_PENALTY = 'attempt_penalty';

	public function check_answer($log)
	{
		if (isset($this->questions[$log->item_id]))
		{
			$q = $this->questions[$log->item_id];
			foreach ($q->answers as $answer)
			{
				if ($log->text == $answer['text']) return $answer['value'];
			}
		}

		if (isset($this->questions[$log->item_id]))
		{
			$q = $this->questions[$log->item_id];
			return $log->text == $q->answers[0]['text'] ? 100 : 0;
		}

		return 0;
	}

	protected function handle_log_widget_interaction($log)
	{
		if ($log->text == $this::ATTEMPT_PENALTY)
		{
			array_push($this->global_modifiers, $log->value);
		}
	}

}

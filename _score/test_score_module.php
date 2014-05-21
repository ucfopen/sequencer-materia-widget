<?php
/**
 * @group App
 * @group Materia
 * @group Score
 * @group HelloWidget
 */
class Test_Score_Modules_Sequencer extends \Basetest
{
	protected function _get_qset()
	{

		return json_decode('
{
  "name": "American Conflicts from 1776 - 1975",
  "qset": {
    "version": 1,
    "data": {
      "name": "American Conflicts from 1776 - 1975",
      "items": [
        {
          "materiaType": "question",
          "id": 1,
          "type": "QA",
          "questions": [
            {
              "text": "American Revolutionary War"
            }
          ],
          "answers": [
            {
              "value": 100,
              "text": 1
            }
          ],
          "options": {
            "description": "American colonists rejected the legitimacy of the Parliament of Great Britain to govern them without representation.\n"
          }
        },
        {
          "materiaType": "question",
          "id": 2,
          "type": "QA",
          "questions": [
            {
              "text": "War of 1812"
            }
          ],
          "answers": [
            {
              "value": 100,
              "text": 2
            }
          ],
          "options": {
            "description": "Americans declared war in 1812 for a number of reasons, including a desire for expansion into the Northwest Territory, trade restrictions  because of Britain\'s ongoing war with France,  impressment of American merchant sailors  into the Royal Navy, British support of  American Indian tribes against American  expansion, and the humiliation of American honour.\n"
          }
        },
        {
          "materiaType": "question",
          "id": 3,
          "type": "QA",
          "questions": [
            {
              "text": "Mexican-American War"
            }
          ],
          "answers": [
            {
              "value": 100,
              "text": 3
            }
          ],
          "options": {
            "description": "An armed conflict between the United States and Mexico in the wake of the U.S. annexation of Texas.\n"
          }
        },
        {
          "materiaType": "question",
          "id": 4,
          "type": "QA",
          "questions": [
            {
              "text": "American Civil War"
            }
          ],
          "answers": [
            {
              "value": 100,
              "text": 4
            }
          ],
          "options": {
            "description": "11 Southern slave states declared their secession from the United States and formed the Confederate States of America.\n"
          }
        },
        {
          "materiaType": "question",
          "id": 5,
          "type": "QA",
          "questions": [
            {
              "text": "Spanish-American War"
            }
          ],
          "answers": [
            {
              "value": 100,
              "text": 5
            }
          ],
          "options": {
            "description": "Includes the Charge of the Rough Riders, at San Juan Hill.\n"
          }
        },
        {
          "materiaType": "question",
          "id": 6,
          "type": "QA",
          "questions": [
            {
              "text": "World War I"
            }
          ],
          "answers": [
            {
              "value": 100,
              "text": 6
            }
          ],
          "options": {
            "description": "More than 9 million combatants were killed in this conflict.\n"
          }
        },
        {
          "materiaType": "question",
          "id": 7,
          "type": "QA",
          "questions": [
            {
              "text": "World War II"
            }
          ],
          "answers": [
            {
              "value": 100,
              "text": 7
            }
          ],
          "options": {
            "description": "Included two opposing military alliances, the Allies and the Axis.\n"
          }
        },
        {
          "materiaType": "question",
          "id": 8,
          "type": "QA",
          "questions": [
            {
              "text": "Korean War"
            }
          ],
          "answers": [
            {
              "value": 100,
              "text": 8
            }
          ],
          "options": {
            "description": "This war was the result of the physical division of Korea.\n"
          }
        },
        {
          "materiaType": "question",
          "id": 9,
          "type": "QA",
          "questions": [
            {
              "text": "Vietnam War"
            }
          ],
          "answers": [
            {
              "value": 100,
              "text": 9
            }
          ],
          "options": {
            "description": "This war followed the First Indochina War and was fought between North Vietnam, supported by its communist allies, and the government of South Vietnam, supported by the U.S. and other anti-communist nations.\n"
          }
        }
      ],
      "options": {
        "penalty": 10
      }
    }
  }
}
');
	}

	protected function _makeWidget($partial = 'false')
	{
		$this->_asAuthor();

		$title = 'SEQUENCER SCORE MODULE TEST';
		$widget_id = $this->_find_widget_id('Sequencer');
		$qset = (object) ['version' => 1, 'data' => $this->_get_qset()];
		return \Materia\Api::widget_instance_save($widget_id, $title, $qset, false);
	}

	public function test_check_answer()
	{
		$this->_test_full_credit();
		$this->_test_partial_credit();
	}

	function _test_full_credit() {
		$inst = $this->_makeWidget('false');
		$play_session = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $play_session);

		$logs = array();

		for ($i=1;$i<10;$i++) {
			$logs[] = json_decode('{
				"text":"'.$i.'",
				"type":1004,
				"value":"",
				"item_id":"'.$qset->data['qset']['data']['items'][$i - 1]['id'].'",
				"game_time":10
			}');
		}

		$output = \Materia\Api::play_logs_save($play_session, $logs);

		$scores = \Materia\Api::widget_instance_scores_get($inst->id);

		$this_score = \Materia\Api::widget_instance_play_scores_get($play_session);

		$this->assertInternalType('array', $this_score);
		$this->assertEquals(100, $this_score[0]['overview']['score']);
	}

	function _test_partial_credit() {
		$inst = $this->_makeWidget('false');
		$play_session = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $play_session);

		$logs = array();

		# Test to make sure that multiple attempts will dock the score
		for ($i=1;$i<10;$i++) {
			$logs[] = json_decode('{
				"text":"'.$i.'",
				"type":1004,
				"value":"",
				"item_id":"'.$qset->data['qset']['data']['items'][$i - 1]['id'].'",
				"game_time":10
			}');
		}
		for ($i=0;$i<3;$i++) {
			$logs[] = json_decode('{
				"text":"attempt_penalty",
				"type":1001,
				"value":-'.$qset->data['qset']['data']['options']['penalty'].',
				"item_id":null,
				"game_time":'.(10 + $i).'
			}');
		}

		$output = \Materia\Api::play_logs_save($play_session, $logs);

		$scores = \Materia\Api::widget_instance_scores_get($inst->id);

		$this_score = \Materia\Api::widget_instance_play_scores_get($play_session);

		$this->assertInternalType('array', $this_score);
		$this->assertEquals(70, $this_score[0]['overview']['score']);
	}
}

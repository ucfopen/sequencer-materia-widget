<?php
/**
 * @group App
 * @group Materia
 * @group Score
 * @group Sequencer
 */
class Test_Score_Modules_Sequencer extends \Basetest
{
	protected function _get_qset($penalty)
	{
		return json_decode('
			{
				"items":[
					{
						"items":[
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"1",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"q1",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	},
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"2",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"q2",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	},
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"3",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"q3",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	},
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"4",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"q4",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	},
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"5",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"q5",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	}
						],
						"name":"",
						"options":{},
						"assets":[],
						"rand":false
					}
				],
				 "name":"",
				 "options":
				 	{
				 		"penalty":'.$penalty.',
				 		"freeTries":0
				 	},
				 "assets":[],
				 "rand":false
			}');
	}

	protected function _make_widget($penalty = 15)
	{
		$this->_asAuthor();

		$title = 'SEQUENCER SCORE MODULE TEST';
		$widget_id = $this->_find_widget_id('Sequencer');
		$qset = (object) ['version' => 1, 'data' => $this->_get_qset($penalty)];

		return \Materia\Api::widget_instance_save($widget_id, $title, $qset, false);
	}

	public function test_check_answer()
	{
		$inst = $this->_make_widget();
		$play_session = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $play_session);

		$logs = array();
		$logs[] = json_decode('{
			"text":"1",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][0]['id'].'",
			"game_time":10
		}');
		$logs[] = json_decode('{
			"text":"2",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][1]['id'].'",
			"game_time":11
		}');
		$logs[] = json_decode('{
			"text":"3",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][2]['id'].'",
			"game_time":11
		}');
		$logs[] = json_decode('{
			"text":"4",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][3]['id'].'",
			"game_time":11
		}');
		$logs[] = json_decode('{
			"text":"5",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][4]['id'].'",
			"game_time":11
		}');
		$logs[] = json_decode('{
			"text":"",
			"type":2,
			"value":"",
			"item_id":"0",
			"game_time":12
		}');

		$output = \Materia\Api::play_logs_save($play_session, $logs);

		$scores = \Materia\Api::widget_instance_scores_get($inst->id);

		$this_score = \Materia\Api::widget_instance_play_scores_get($play_session);

		$this->assertInternalType('array', $this_score);
		$this->assertEquals(100, $this_score[0]['overview']['score']);
	}

	public function test_check_penalty()
	{
		$penalty = 15;
		$inst = $this->_make_widget($penalty);
		$play_session = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $play_session);

		$logs = array();
		$logs[] = json_decode('{
			"text":"attempt_penalty",
			"type":1001,
			"value":-'.$penalty.',
			"item_id":"0",
			"game_time":10
		}');
		$logs[] = json_decode('{
			"text":"1",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][0]['id'].'",
			"game_time":10
		}');
		$logs[] = json_decode('{
			"text":"2",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][1]['id'].'",
			"game_time":11
		}');
		$logs[] = json_decode('{
			"text":"3",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][2]['id'].'",
			"game_time":11
		}');
		$logs[] = json_decode('{
			"text":"4",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][3]['id'].'",
			"game_time":11
		}');
		$logs[] = json_decode('{
			"text":"5",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][4]['id'].'",
			"game_time":11
		}');
		$logs[] = json_decode('{
			"text":"",
			"type":2,
			"value":"",
			"item_id":"0",
			"game_time":12
		}');

		$output = \Materia\Api::play_logs_save($play_session, $logs);

		$scores = \Materia\Api::widget_instance_scores_get($inst->id);

		$this_score = \Materia\Api::widget_instance_play_scores_get($play_session);

		$this->assertInternalType('array', $this_score);
		$this->assertEquals(85, $this_score[0]['overview']['score']);
	}
}
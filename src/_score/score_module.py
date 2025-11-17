from scoring.module import ScoreModule


class Sequencer(ScoreModule):

    ATTEMPT_PENALTY = 'attempt_penalty'

    def check_answer(self, log):
        q = self.get_question_by_item_id(log.item_id)

        if q is not None:
            for answer in q["answers"]:
                if str(log.text) == str(answer["text"]):
                    return int(answer["value"])

        if q is not None:
            return 100 if log.text == q["answers"][0]["text"] else 0

        return 0

    def handle_log_widget_interaction(self, log):
        if log.text == self.ATTEMPT_PENALTY:
            self.global_modifiers.append(int(log.value))

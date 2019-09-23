import codecs

import app.protoutils.data_pb2

def load_raw_data_from_file(path):
    """
    Input: path, path of the file
    Output: list of NERLabeledSentence
    """
    sentence_msg_list = []
    sentence = app.protoutils.data_pb2.NERLabeledSentence()
    for line in codecs.open(path, 'r', encoding='utf-8'):
        line = line.strip()
        if not line:
            if len(sentence.labeled_word_list) > 0:
                sentence_msg_list.append(sentence)
                sentence = app.protoutils.data_pb2.NERLabeledSentence()
        else:
            if line[0] == " ":
                continue
            else:
                word = line.split()
                assert len(word) >= 2
                labeled_word_msg = app.protoutils.data_pb2.NERLabeledWord()
                labeled_word_msg.word = word[0]
                labeled_word_msg.tag = word[1]
                sentence.labeled_word_list.extend([labeled_word_msg])
    if len(sentence.labeled_word_list) > 0:
        sentence_msg_list.append(sentence)
    return sentence_msg_list

class SentenceHandler(object):
    def __init__(self, sentence_msg):
        self.sentence_msg = sentence_msg

    @staticmethod
    def validate_sentance(sentence_msg):
        for i, word_msg in enumerate(sentence_msg.labeled_word_list):
            if word_msg.tag == 'O':
                continue
            tag_parts = word_msg.tag.split('-')
            if tag_parts[0] == 'B':
                continue
            elif i == 0 or sentence_msg.labeled_word_list[i-1].tag == 'O':
                sentence_msg.labeled_word_list[i].tag = f'B-{tag_parts[1]}'
        return True

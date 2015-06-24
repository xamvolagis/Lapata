cimport cython
import sys
import csv
from collections import Counter
import numpy as np
cimport numpy as np
DTYPE = np.int
ctypedef np.int_t DTYPE_t

cdef tuple ENG_DPRLIST = ('NMOD', 'P', 'PMOD', 'SBJ', 'OBJ', 'ADV', 'NAME',
                          'VC', 'COORD', 'DEP', 'TMP', 'CONJ', 'LOC', 'AMOD',
                          'PRD', 'APPO', 'IM', 'HYPH', 'HMOD', 'SUB', 'OPRD',
                          'SUFFIX', 'TITLE', 'DIR', 'POSTHON', 'MNR', 'PRP',
                          'PRT', 'LGS', 'EXT', 'PRN', 'LOC-PRD', 'EXTR',
                          'DTV', 'PUT', 'GAP-SBJ', 'GAP-OBJ', 'DEP-GAP',
                          'GAP-PRD', 'GAP-TMP', 'PRD-TMP', 'GAP-LGS', 'PRD-PRP',
                          'BNF', 'GAP-LOC', 'DIR-GAP', 'LOC-OPRD', 'VOC',
                          'GAP-PMOD', 'GAP-VC', 'EXT-GAP', 'ADV-GAP',
                          'GAP-NMOD', 'GAP-LOC-PRD', 'DTV-GAP', 'AMOD-GAP',
                          'GAP-PRP', 'DIR-PRD', 'GAP-MNR', 'EXTR-GAP',
                          'MNR-PRD', 'LOC-TMP', 'MNR-TMP', 'LOC-MNR', 'GAP-SUB',
                          'GAP-PUT', 'GAP-OPRD', 'DIR-OPRD')
cdef tuple GER_DPRLIST = ('NK', 'PUNC', 'MO', 'SB', 'OC', 'OA', 'CJ', 'MNR', 'CD',
                          'AG', 'PNC', 'PD', 'CP', 'OP', 'RC', 'NG', 'DA', 'SVP',
                          'PM', 'PG', 'APP', 'RE', 'NMC', 'CM', 'CC', 'PAR',
                          'CVC', 'JU', 'SBP', 'EP', 'AC', 'AMS', 'PH', 'UC',
                          'DH', 'OG', 'RS', 'VO', 'DM', 'AVC')
cdef dict DPRLISTS = {'de': GER_DPRLIST, 'ger': GER_DPRLIST,
                      'eng': ENG_DPRLIST, 'en': ENG_DPRLIST}

cdef tuple ENG_APREDLIST = ('A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'AA', 'AM',
                            'AM-ADV', 'AM-CAU', 'AM-DIR', 'AM-DIS', 'AM-EXT',
                            'AM-LOC', 'AM-MNR', 'AM-MOD', 'AM-NEG', 'AM-PNC',
                            'AM-PRD', 'AM-PRT', 'AM-REC', 'AM-TM', 'AM-TMP',
                            'C-A0', 'C-A1', 'C-A2', 'C-A3', 'C-A4', 'C-AM-ADV',
                            'C-AM-CAU', 'C-AM-DIR', 'C-AM-DIS', 'C-AM-EXT',
                            'C-AM-LOC', 'C-AM-MNR', 'C-AM-NEG', 'C-AM-PNC',
                            'C-AM-TMP', 'R-A0', 'R-A1', 'R-A2', 'R-A3', 'R-A4',
                            'R-AA', 'R-AM-ADV', 'R-AM-CAU', 'R-AM-DIR',
                            'R-AM-EXT', 'R-AM-LOC', 'R-AM-MNR', 'R-AM-PNC',
                            'R-AM-TMP', 'C-R-AM-TMP')
cdef tuple GER_APREDLIST = ('A0', 'A1', 'A2', 'A3', 'A4',
                           'A5', 'A6', 'A7', 'A8', 'A9')
cdef dict APREDLISTS = {'de': GER_APREDLIST, 'ger': GER_APREDLIST,
                        'eng': ENG_APREDLIST, 'en': ENG_APREDLIST}

@cython.boundscheck(False)
@cython.wraparound(False)
cdef main_(str inf, str outf, str lang, int N, bint SCORE, bint MULTI):
    cdef:
        dict pos_nums = dict()
        dict verbs = dict()
        dict v_counts = dict()
        dict gold_verbs = dict()
        dict gold_apreds = dict()
        int i, head, pos, M, hnum, rnum
        str verb, temp1, temp2
        int root_id = 0
        bint valid
        np.ndarray[dtype=DTYPE_t, ndim=2] temp = np.zeros((256, 2), dtype=DTYPE)
        np.ndarray[dtype=DTYPE_t, ndim=1] valids = np.zeros(256, dtype=DTYPE)
    for i, temp1 in enumerate(DPRLISTS[lang][:N]):
        pos_nums[temp1] = i
    pos_nums["EXTRA"] = N
    if SCORE:
        for i, temp1 in enumerate(APREDLISTS[lang]):
            gold_apreds[temp1] = i
        M = len(gold_apreds)
    i = 0
    cdef np.ndarray[dtype=DTYPE_t, ndim=3] tempsc=np.zeros((256, M, N), dtype=DTYPE)
    with open(inf, 'r') as csvfile:
        """
        Read in the data, must be in Conll X format
        relevant row indices:
        0  : word index
        1  : word string
        8  : HEAD
        10 : DEPREL
        14 : Start of APREDs
        """
        rdr = csv.reader(csvfile, delimiter='\t')
        for row in rdr:
            if len(row) == 0:
                continue
            hnum, rnum = int(row[8]), int(row[0])
            if rnum == 1 and i > 1:
                for head, pos in temp[1: i+1]:
                    if head == root_id:
                        verbs[verb][pos] += 1
                try:
                    temp[1] = hnum, pos_nums.get(row[10], N)
                except:
                    temp[1] = -1, -1
                gold_verbs[verb] += tempsc[root_id]
                v_counts[verb] += valids[root_id]
                valids[:] = 0
                tempsc[:] = 0
            elif hnum == 0 and row[10] == "ROOT":
                root_id = rnum
                verb = row[1].lower()
                if (not verb[0].isalpha()) or (not verb[len(verb)-1].isalpha()):
                    verb = '-----'
                if verb not in verbs:
                    verbs[verb] = np.zeros(N+1, dtype=DTYPE)
                    v_counts[verb] = 0
                if SCORE and verb not in gold_verbs:
                    gold_verbs[verb] = np.zeros((M, N), dtype=DTYPE)
                temp[rnum] = -1, -1
            else:
                try:
                    temp[rnum] = hnum, pos_nums.get(row[10], N)
                except:
                    temp[rnum] = -1, -1
            i = rnum
            if SCORE and len(row) >= 14:
                for temp1 in row[14:]:
                    if temp1 not in  {'-', '_'}:
                        if row[10] in pos_nums:
                            valid = True
                            tempsc[hnum][gold_apreds[
                                temp1]][pos_nums[row[10]]] += 1
                            if not MULTI:
                                break
                if valid and not MULTI:
                    valids[hnum] += 1
                    valid = False

    del verbs['-----']
    cdef:
        double PT, CT, Pm, Cm, NT, Ct, Pt, Nt, Ntc, NTc, T
        np.ndarray C
        np.ndarray G
    if SCORE:
        f = open("verblog.txt", 'w')
        NT = PT = Pm = CT = Cm = T = 0
        for verb in verbs:
            Nt = Pt = Ct = 0
            G = gold_verbs[verb]
            C = verbs[verb]
            #Nt = np.sum(G)
            #Ntc = sum(C)
            #if Ntc >= Nt:
            #    print(Nt, Ntc)
            #Nt = min(Nt, Ntc)
            # Nt = np.sum(temp1)
            Nt = min(sum(C), np.sum(G)) if MULTI else v_counts[verb]
            if Nt > 0:
                f.write(verb + ":\n" + str(C) + '\n' + str(G) + '\n')
                T += 1
                NT += Nt
                NTc += Ntc
                for i in range(M):
                    try:
                        Pt += max(min(G[i][pos], C[pos]) for pos in np.nonzero(G[i])[0])
                    except:
                        Pt += 0
                Pm += Pt
                PT += Pt/Nt
                for i in range(N):
                    try:
                        Ct += max(min(G[pos][i], C[i]) for pos in range(M))
                    except:
                        Ct += 0
                Cm += Ct
                CT += Ct/Nt # NT or Ntc???
                            # this wouldn't be a problem
                            # if there were no missing annotations
        print("Micro averages: PU={:.3%}, CO={:.3%}, F1={:.3%}".format(Pm/NT, Cm/NT,
                                                                          2*(Pm*Cm/(NT*NT))/(Pm/NT+Cm/NT)))
        print("Macro averages: PU={:.3%}, CO={:.3%}, F1={:.3%}".format(PT/T, CT/T,
                                                                          2*(PT*CT/T)/(PT+CT)))
        f.close()
    with open(outf, 'w') as csvout:
        """
        Write the results back out
        """
        wrt = csv.writer(csvout, delimiter='\t')
        wrt.writerow(["Verbs\Deprels"] +  list(DPRLISTS[lang][:N]) + ["EXTRA"])
        for verb in sorted(verbs.keys()):
            wrt.writerow([verb] + [verbs[verb][pos_nums[temp1]]
                                for temp1 in list(DPRLISTS[lang][:N])] + [verbs[verb][N]])


def main(inf, outf, LANG='de', NSYPOS=22, SCORE=True, MULTI=False):
    main_(inf, outf, LANG, NSYPOS, SCORE, MULTI)

if __name__ == '__main__':
    main()


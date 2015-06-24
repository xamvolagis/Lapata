import pywikibot as pwb
from pywikibot import pagegenerators as pg
import numpy as np
DTYPE = np.int


class AssociationBot(pwb.WikidataBot):
    PROPERTY_BLACKLIST = {10,     # relevant video
                          109,    # image of signature
                          1283,   # filmography
                          1332,   # coordinate
                          1333,   # coordinate
                          1334,   # coordinate
                          1335,   # coordinate
                          1348,   # URL for the website AlgaeBase
                          1442,   # image of grave...
                                  # I can't believe this exists
                          158,    # seal image
                          1621,   # detail map
                          166,    # award received
                          1766,   # place name of sign
                          18,     # commons media file
                          181,    # range map of a taxon
                          237,    # coat of arms
                          242,    # locator map image
                          39,     # position held
                          41,     # flag image
                          411,    # canonization status
                          443,    # pronounciation file
                          51,     # relevant sound
                          675,    # google books identifier
                          94,     # coat of arms image
                          948,    # wikivoyage banner
                          989,    # spoken text
                          990,    # voice recording
                          996    # scan file
                          }

    def __init__(self, num_relations=10000, lang='en',
                 save_keys=False, one_to_one=False, *args, **kwargs):
        """Bot for finding associations from wikidata.

        """
        self.lang = lang
        self.maxsize = num_relations
        self.one_to_one = one_to_one
        super(pwb.WikidataBot, self).__init__(**kwargs)
        self.ref_site = pwb.getSite(self.lang, 'wikipedia')
        self.site = pwb.getSite('wikidata', 'wikidata')
        self.repo = self.site.data_repository()
        self.associations = np.zeros((num_relations, 3), dtype=DTYPE)
        self.use_from_page = True
        self.save_keys = save_keys
        self.index = 0
        self.keys = {}

    def item_page_from_id(self, wikidata_id):
        if isinstance(wikidata_id, int):
            wikidata_id = "Q" + str(wikidata_id)
        return pwb.ItemPage(self.repo, wikidata_id)

    def item_page_from_title(self, wikipedia_title):
        return pwb.ItemPage.fromPage(pwb.Page(self.ref_site, wikipedia_title))

    def treat(self, _, item_page):
        claims = item_page.claims
        for claim, link_list in claims.items():
            if self.one_to_one and len(link_list) > 1:
                continue
            for link in link_list:
                try:
                    prop = int(claim[1:])
                    if prop in self.PROPERTY_BLACKLIST:
                        break
                    source = int(item_page.id[1:])
                    target = int(link.target.id[1:])
                    self.associations[self.index] = (prop, source, target)
                    if self.save_keys:
                        self.keys[source] = item_page.sitelinks[
                            "{}wiki".format(self.lang)]
                        self.keys[target] = (
                            link.target.sitelinks["{}wiki".format(self.lang)])
                    self.index += 1
                except:
                    pass

    def set_cat(self, cat_str, site=None):
        if not site:
            site = self.ref_site
        try:
            self.cat = pwb.Category(pwb.Link(cat_str, site))
        except:
            self.cat = None

    def make_gen(self, recurse=5, num_pages=-1):
        if num_pages == -1:
            num_pages = self.maxsize - self.index
        try:
            self.generator = pg.CategorizedPageGenerator(self.cat,
                                                         recurse=recurse,
                                                         total=num_pages)
        except:
            self.generator = iter(())

    def keygen(self):
        self.save_keys = True
        for row in self.associations:
            try:
                self.keys[row[1]] = self.item_page_from_id(
                    int(row[1])).get()['sitelinks']["{}wiki".format(self.lang)]
            except:
                pass
            try:
                self.keys[row[2]] = self.item_page_from_id(
                    int(row[2])).get()['sitelinks']["{}wiki".format(self.lang)]
            except:
                pass

    def run_on_cat(self, cat_str, site=None,
                   recurse=5, num_pages=-1):
        if num_pages == -1:
            num_pages = self.maxsize - self.index
        self.set_cat(cat_str, site=site)
        self.make_gen(recurse=recurse, num_pages=num_pages)
        self.run()

    def sort(self):
        self.associations = self.associations[
            self.associations[
                :self.index, 0].argsort()].resize((self.maxsize, 3))

    def save_bot(self, filename=None):
        if not filename:
            filename = "wikidata-{}-{!s}-bot-associations.txt".format(
                self.ref_site.lang, self.maxsize)
        with open(filename, 'w') as f:
            f.write("{}\n".format(self.ref_site.lang))
            # f.write("{} {} {}".format("property", "source", "target"))
            for i in range(self.index):
                f.write(' '.join(map(str, self.associations[i])) + '\n')

    @classmethod
    def load_from_file(cls, filename, num_relations=10000):
        with open(filename, 'r') as f:
            bot = cls(num_relations=num_relations, lang=f.readline().rstrip())
            i = 0
            for line in f:
                bot.associations[i] = tuple(map(int, line.split()))
                i += 1
        bot.index = i
        return bot


def main(*args, **kwargs):
    pass


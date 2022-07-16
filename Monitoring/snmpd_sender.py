#!/usr/bin/env python3
import subprocess
import sys


class VarnishStatus:

    def __init__(self, oid_prefix):

        i = 'integer'
        s = 'string'
        c = 'counter'
        g = 'gauge'
        t = 'timeticks'
        o = 'octet'

        self.v_s = {
            "SMA.s0.c_bytes": ['1.1.1.0', i, 'Storage Mem size in KB'],  # TODO kB
            "MAIN.uptime": ['1.1.3.0', t, 'The Uptime of the cache in timeticks'],
            # TODO MB
            "SMA.s0.g_space": ['1.2.5.1.0', i, 'The value of the cache_mem parameter in MB'],
            "SMA.s0.c_bytes": ['1.3.1.3.0', i, 'cacheMemUsage'],  # TODO kB
            'MAIN.n_object': ['1.3.1.7.0', i, 0, 'cacheNumObjCount'],
        }

        self.fakes = [
            ['1.1.2.0', i, 0, 'Storage Swap size in KB'],
            ['1.2.1.0', s, 'ivukotic@uchicago.edu', 'Cache Administrator E-Mail address'],
            ['1.2.2.0', s, 'varnish', 'Cache Software Name'],
            ['1.2.3.0', s, '7.1', 'Cache Software Version'],
            ['1.2.4.0', s, 'ALL,1', 'Logging Facility.'],
            ['1.2.5.2.0', i, 0, 'cacheSwapMaxSize'],
            ['1.2.5.3.0', i, 0, 'cacheSwapHighWM'],
            ['1.2.5.4.0', i, 0,  'cacheSwapLowWM'],
            ['1.2.6.0', s, 'varnish-test', 'cacheUniqName'],  # TODO proper instance

            ['1.3.1.1.0', i, 0, 'cacheSysPageFaults'],
            ['1.3.1.2.0', i, 0, 'cacheSysNumReads'],
            ['1.3.1.4.0', i, 0, 'cacheCpuTime'],
            ['1.3.1.5.0', i, 0, 'cacheCpuUsage'],
            ['1.3.1.6.0', i, 0, 'cacheMaxResSize'],
            ['1.3.1.8.0', i, 0, 'cacheCurrentLRUExpiration'],
            ['1.3.1.9.0', i, 0, 'cacheCurrentUnlinkRequests'],
            ['1.3.1.10.0', i, 0, 'cacheCurrentUnusedFDescrCnt'],
            ['1.3.1.11.0', i, 0, 'cacheCurrentResFileDescrCnt'],
            ['1.3.1.12.0', i, 0, 'cacheCurrentFileDescrCnt'],
            ['1.3.1.13.0', i, 0, 'cacheCurrentFileDescrMax'],
        ]

        self.oid_prefix = oid_prefix

        # self.data is a dictionary that contains all systemd service data using programmatically
        # generated OID as the key:
        # '1.3.9950.1.115.115.115.100': ('integer', 0, 'sssd'),
        self.data = {}

        # self.sorted_oids enables iterating over the OIDs in correct order
        # while having the data in a non-ordered dictionary (self.data).
        self.sorted_oids = []

        # Get systemd service status and store it in self.data. Also populate self.sorted_oids.
        self.cache_service_status()

        # print('data', self.data)
        # print('sorted oids', self.sorted_oids)

    def cache_service_status(self):

        # Temporary data structure used to create sorted oid list later
        oids = []  # self.oid_prefix]

        lines = subprocess.check_output(["/usr/bin/varnishstat -1"],
                                        shell=True).decode("UTF-8").strip().split("\n")

        # print('metrics loaded:', len(lines))
        for line in lines:
            [v_name, v_val, v_smt] = line.split()[:3]
            sq = self.get_sq(v_name)
            if sq:
                [sq_oid, sq_type, sq_name] = sq
                sq_oid = self.oid_prefix+'.'+sq_oid
                self.data[sq_oid] = (sq_type, v_val, sq_name)
                oids.append(sq_oid)

        # print('add fakes')
        for fake in self.fakes:
            sq_oid = self.oid_prefix+'.'+fake[0]
            oids.append(sq_oid)
            self.data[sq_oid] = (fake[1], fake[2], fake[3])

        # Sort the oids array. Lovingly borrowed from here:
        #
        # https://rosettacode.org/wiki/Sort_a_list_of_object_identifiers#Python
        #
        # The array sorted array is then used to output data in the correct order when using
        # getnext (snmpwalk)
        self.sorted_oids = sorted(oids, key=lambda x: list(map(int, x.split('.'))))

    def get_sq(self, name):
        if name in self.v_s:
            return self.v_s[name]
        return


def getline():
    line = sys.stdin.readline().strip()
    writelog(line)
    return line


def output(line):
    sys.stdout.write(line + "\n")
    sys.stdout.flush()
    writelog(">> "+line)


def writelog(line):
    f = open("/tmp/snmp.log", "a")
    f.write(line+'\n')
    f.close()


def main():
    oid_prefix = "1.3.6.1.4.1.3495"
    s = VarnishStatus(oid_prefix)

    try:
        while True:
            command = getline()

            if command == "":
                sys.exit(0)
            elif command == "PING":
                output("PONG")

            elif command == "set":
                oid = getline()
                type_and_value = getline()
                output("not-writable")

            elif command == "get":
                oid = getline()
                cl_oid = oid.lstrip(".")
                if cl_oid in s.data:
                    output(str(oid))
                    output(str(s.data[cl_oid][0]))
                    output(str(s.data[cl_oid][1]))
                else:
                    output("NONE")

            elif command == "getnext":
                oid = getline()
                cl_oid = oid.lstrip(".")

                # remove trailing zeroes from the oid
                while len(oid) > 0 and oid[-2:] == ".0" and oid not in s.sorted_oids:
                    oid = oid[:-2]

                # does provided oid exist in the list
                if cl_oid in s.sorted_oids:
                    # exact match return next one unless this was the last one
                    ni = s.sorted_oids.index(cl_oid) + 1
                    if ni >= len(s.sorted_oids) - 1:
                        output("NONE")
                    else:
                        output("." + str(s.sorted_oids[ni]))
                        output(str(s.data[s.sorted_oids[ni]][0]))
                        output(str(s.data[s.sorted_oids[ni]][1]))
                else:
                    # not matched, try to find related
                    match = False
                    for ex_oid in s.sorted_oids:
                        if ex_oid.startswith(cl_oid):
                            output("." + str(ex_oid))
                            output(str(s.data[ex_oid][0]))
                            output(str(s.data[ex_oid][1]))
                            match = True
                            break
                    if not match:
                        output("NONE")
            else:
                # command not recognized
                pass

    except Exception as ep:
        f = open("/var/lib/snmp/varnish-status.err.log", "a")
        f.write(ep)
        f.close()
        # print(ep.with_traceback)


if __name__ == "__main__":
    main()

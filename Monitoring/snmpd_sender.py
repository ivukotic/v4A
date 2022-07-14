#!/usr/bin/env python3
import subprocess
import sys


class VarnishStatus:

    def __init__(self, oid_prefix):

        i = 'INTEGER'
        s = 'STRING'
        c3 = 'Counter32'
        c6 = 'Counter64'
        g = 'GAUGE'
        t = 'TIMETICKS'

        self.v_s = {
            "SMA.s0.g_space": ['1.1.1.0', i, 'Storage Mem size in KB'],
            "fake1": ['1.1.2.0', i, 'Storage Swap size in KB'],
            "MAIN.uptime": ['1.1.3.0', t, 'The Uptime of the cache in timeticks'],
            "fake2": ['1.2.1.0', s, 'Cache Administrator E-Mail address'],
            "fake3": ['1.2.2.0', s, 'Cache Software Name'],
            "fake4": ['1.2.3.0', s, 'Cache Software Version'],
            "fake5": ['1.2.4.0', s, 'Logging Facility.']
        }

        self.fakes = [
            ['1.1.2.0', i, 0, 'Storage Swap size in KB'],
            ['1.2.1.0', s, 'ivukotic@uchicago.edu', 'Cache Administrator E-Mail address'],
            ['1.2.2.0', s, 'varnish', 'Cache Software Name'],
            ['1.2.3.0', s, '7.1', 'Cache Software Version'],
            ['1.2.4.0', s, 'kibana', 'Logging Facility.']
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
    return sys.stdin.readline().strip()


def output(line):
    sys.stdout.write(line + "\n")
    sys.stdout.flush()


def main():
    oid_prefix = "1.3.6.1.4.1.3495"
    s = VarnishStatus(oid_prefix)

    try:
        while True:
            command = getline()

            f = open("/tmp/snmp.log", "a")
            f.write(command)
            f.close()

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
                output(str(oid))
                output(str(s.data[oid.lstrip(".")][0]))
                output(str(s.data[oid.lstrip(".")][1]))
                sys.exit(0)

            elif command == "getnext":
                oid = getline()
                ni = s.sorted_oids.index(oid.lstrip(".")) + 1
                if ni >= len(s.sorted_oids) - 1:
                    sys.exit(0)
                else:
                    output("." + str(s.sorted_oids[ni]))
                    output(str(s.data[s.sorted_oids[ni]][0]))
                    output(str(s.data[s.sorted_oids[ni]][1]))

            else:
                pass

    except Exception as ep:
        f = open("/var/lib/snmp/varnish-status.err.log", "a")
        f.write(ep)
        f.close()
        # print(ep.with_traceback)


if __name__ == "__main__":
    main()


with open('d411.bin', 'rb') as inf:
    i = 0

    for x in inf.read():
        print('rom[{}] = 8\'h{:02x};'.format(i, x))
        i += 1

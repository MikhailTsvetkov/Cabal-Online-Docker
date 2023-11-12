#!/usr/bin/python3

import asyncio
import logging
import sys

BUFFER_SIZE = 65536
CONNECT_TIMEOUT_SECONDS = 5

#port_in = int(sys.argv[1])
#port_out = int(sys.argv[2])

#filename_item = bytes(sys.argv[3], "utf8")
#filename_mobs = bytes(sys.argv[4], "utf8")
#filename_warp = bytes(sys.argv[5], "utf8")

proxy_id = int(sys.argv[1])

conf_file = open("/etc/cabal/GlobalMgrSvr.ini", "r")
table_begin = 0
while True:
    line = conf_file.readline()
    if not line:
        break
    if "[NetLib]" in line:
        table_begin = 1
        continue
    if "[" in line:
        table_begin = 0
        continue
    if len(line.strip()) == 0:
        continue
    if table_begin == 1 and "Port=" in line:
        port_out = int(line.split("=")[1])
        #print(port_out)
        break
conf_file.close


conf_file = open("/etc/cabal_structure/proxy_list", "r")
table_begin = 0
while True:
    line = conf_file.readline()
    if not line:
        break
    if "[ProxyId]" in line and "#" not in line:
        table_begin = 1
        continue
    if len(line.strip()) == 0:
        continue
    if table_begin == 1:
        proxy_data = line.split()
        conf_poxy_id = int(proxy_data[0])
        if proxy_id == conf_poxy_id:
            port_in = int(proxy_data[1])
            filename_item = bytes(proxy_data[2], "utf8")
            filename_mobs = bytes(proxy_data[3], "utf8")
            filename_warp = bytes(proxy_data[4], "utf8")
            #print(filename_item)
            break
conf_file.close

filename_item = filename_item+bytes(64-len(filename_item))
filename_mobs = filename_mobs+bytes(64-len(filename_mobs))
filename_warp = filename_warp+bytes(64-len(filename_warp))

def create_logger():
  logger = logging.getLogger('proxy')
  logger.setLevel(logging.INFO)

  consoleHandler = logging.StreamHandler()
  consoleHandler.setLevel(logging.DEBUG)

  formatter = logging.Formatter(
    '%(asctime)s - %(threadName)s - %(message)s')
  consoleHandler.setFormatter(formatter)

  logger.addHandler(consoleHandler)

  return logger

logger = create_logger()

def client_connection_string(writer):
  return '{} -> {}'.format(
    writer.get_extra_info('peername'),
    writer.get_extra_info('sockname'))

def remote_connection_string(writer):
  return '{} -> {}'.format(
    writer.get_extra_info('sockname'),
    writer.get_extra_info('peername'))

async def proxy_data(reader, writer, connection_string):
  try:
    while True:
      data = await reader.read(BUFFER_SIZE)
      if not data:
        break

      if len(data) == 785:
        opCode = data[8:10]
        if opCode == b'\xf7\x02':
          data = data[:15]+filename_item+data[79:272]+filename_mobs+data[336:529]+filename_warp+data[593:]
          # print (data)

      writer.write(data)
      await writer.drain()
  except Exception as e:
    logger.info('proxy_data_task exception {}'.format(e))
  finally:
    writer.close()
    logger.info('close connection {}'.format(connection_string))

async def accept_client(client_reader, client_writer, remote_address, remote_port):
  client_string = client_connection_string(client_writer)
  logger.info('accept connection {}'.format(client_string))
  try:
    (remote_reader, remote_writer) = await asyncio.wait_for(
      asyncio.open_connection(host = remote_address, port = remote_port),
      timeout = CONNECT_TIMEOUT_SECONDS)
  except asyncio.TimeoutError:
    logger.info('connect timeout')
    logger.info('close connection {}'.format(client_string))
    client_writer.close()
  except Exception as e:
    logger.info('error connecting to remote server: {}'.format(e))
    logger.info('close connection {}'.format(client_string))
    client_writer.close()
  else:
    remote_string = remote_connection_string(remote_writer)
    logger.info('connected to remote {}'.format(remote_string))
    asyncio.ensure_future(proxy_data(client_reader, remote_writer, remote_string))
    asyncio.ensure_future(proxy_data(remote_reader, client_writer, client_string))

def parse_addr_port_string(addr_port_string):
  addr_port_list = addr_port_string.rsplit(':', 1)
  return (addr_port_list[0], int(addr_port_list[1]))

def print_usage_and_exit():
  logger.error(
    'Usage: {} <listen addr> [<listen addr> ...] <remote addr>'.format(
      sys.argv[0]))
  sys.exit(1)

def main():
  #if (len(sys.argv) < 3):
  #  print_usage_and_exit()

  try:
    #local_address_port_list = map(parse_addr_port_string, sys.argv[1:-1])
    (local_address, local_port) = ('127.0.0.1', port_in)
    #(remote_address, remote_port) = parse_addr_port_string(sys.argv[-1])
    (remote_address, remote_port) = ('127.0.0.1', port_out)
  except:
    print_usage_and_exit()

  def handle_client(client_reader, client_writer):
    asyncio.ensure_future(accept_client(
      client_reader = client_reader, client_writer = client_writer,
      remote_address = remote_address, remote_port = remote_port))

  loop = asyncio.get_event_loop()
  try:
    server = loop.run_until_complete(
      asyncio.start_server(
        handle_client, host = local_address, port = local_port))
  except Exception as e:
    logger.error('Bind error: {}'.format(e))
    sys.exit(1)

  for s in server.sockets:
    logger.info('listening on {}'.format(s.getsockname()))

  try:
    loop.run_forever()
  except KeyboardInterrupt:
    pass

if __name__ == '__main__':
  main()

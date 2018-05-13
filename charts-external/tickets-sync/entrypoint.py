from sqlalchemy import create_engine
import os, time, datetime, sys


spark_engine = create_engine('mysql://{}:{}@{}/{}'.format(os.environ['SPARKDB_USER'],
                                                          os.environ['SPARKDB_PASS'],
                                                          os.environ['SPARKDB_HOST'],
                                                          os.environ['SPARKDB_NAME']))


profile_engine = create_engine('mysql://{}:{}@{}/{}'.format(os.environ['PROFILEDB_USER'],
                                                            os.environ['PROFILEDB_PASS'],
                                                            os.environ['PROFILEDB_HOST'],
                                                            os.environ['PROFILEDB_NAME']))


spark_engine.connect().close()
profile_engine.connect().close()


def get_spark_entered_tickets(min_first_entry_timestamp=None):
    entered_tickets = set()
    conn = spark_engine.connect()
    # if min_first_entry_timestamp:
    #     timestamp_query = "and first_entrance_timestamp > '{}'".format(min_first_entry_timestamp - datetime.timedelta(minutes=5))
    # else:
    timestamp_query = ''
    last_first_entrance_timestamp = None
    last_ticket_number = None
    for row in conn.execute('select ticket_number, first_entrance_timestamp from tickets where inside_event=1 {}'.format(timestamp_query)):
        entered_tickets.add(int(row[0]))
        if row[1] and (not last_first_entrance_timestamp or last_first_entrance_timestamp < row[1]):
            last_first_entrance_timestamp = row[1]
            last_ticket_number = row[0]
    conn.close()
    print('got {} tickets, last first entrance: {}, last ticket number: {}'.format(len(entered_tickets),
                                                                                   last_first_entrance_timestamp,
                                                                                   last_ticket_number))
    sys.stdout.flush()
    return entered_tickets, last_first_entrance_timestamp


def update_profiles_entered_tickets(ticket_numbers, batch_size=None):
    if not batch_size:
        conn = profile_engine.connect()
        result = conn.execute('update field_data_ticket_state '
                              'set ticket_state_target_id=5 '
                              'where ticket_state_target_id=3 '
                              'and entity_id in ({})'.format(','.join(map(str, ticket_numbers))))
        print('updated {} ticket states from completed (3) to entered (5)'.format(result.rowcount))
        sys.stdout.flush()
        conn.close()
    else:
        current_batch = []
        for ticket_number in ticket_numbers:
            current_batch.append(ticket_number)
            if len(current_batch) >= batch_size:
                update_profiles_entered_tickets(current_batch)
                current_batch = []
        if len(current_batch) > 0:
            update_profiles_entered_tickets(current_batch)


def main():
    last_first_entrance_timestamp = None
    while True:
        spark_entered_tickets, last_first_entrance_timestamp = get_spark_entered_tickets(last_first_entrance_timestamp)
        update_profiles_entered_tickets(spark_entered_tickets, int(os.environ.get('UPDATE_BATCH_SIZE', '500')))
        time.sleep(int(os.environ.get('UPDATE_INTERVAL_SECONDS', '60')))


if __name__ == '__main__':
    main()

#!/bin/bash
set -e

DEV_CHAR=$1
DEV_BLOCK=$2
RUNTIME=30

DIR=$(date +"%H-%M-%S-%d-%m-%y")
mkdir $DIR

#description of the summary
echo "type_bs_jobs_fixedbuf_hipri_depth_iter, BW, IOPS, avg-latency, latency(min), latency(max)" > $DIR/summary.txt
#to give a blank line
echo >> $DIR/summary.txt

function run_fio(){
	param_rw=$1 #randread/randwrite
	param_uring_cmd=$2 #uring_cmd=0/1
	param_iod=$3 #depth
	param_suffix=$4 #iteration
	param_bs=$5 #block_size
	param_engine=$6 #ioengine
	param_fixedbuf=$7 #fixedbufs enabled or not?
	param_hipri=$8 #iopolling enabled or not?
	param_sqt=$9 #sqthread is enabled or not?
	param_batch=${10} #batch size
	param_jobs=${11} #numjobs

	local fname
	local label
	local param_output

	#check type of device
	if [ ${param_uring_cmd} == "1" ]; then
		fname="char"
		label="char"
	else
		fname="block"
		label="block"
	fi

	label=${label}_${param_engine}

	fname=${fname}_${param_bs}_fixedbuffers_${param_fixedbuf}
	param_output=$DIR/${fname}.out

	echo "engine" $param_engine, "uring_cmd" $param_uring_cmd, "rw" $param_rw, "bs" $param_bs, "sqpoll_thread", $param_sqt, "hipri" $param_hipri, "fixedbuf"  $param_fixedbuf, "param_suffix" $param_suffix, output_file $param_output

	echo "engine ${param_engine} uring_cmd ${param_uring_cmd} rw ${param_rw} bs ${param_bs} sqpoll_thread ${param_sqt} hipri ${hipri} fixedbuf  ${param_fixedbuf}  param_suffix ${param_suffix} output_file ${param_output}" >> $DIR/file.info

	if [ ${param_uring_cmd} == "1" ]; then #uring-passthru case
		fio -iodepth=${param_iod} -rw=$param_rw -ioengine=${param_engine} -bs=${param_bs} -numjobs=${param_jobs} -runtime=${RUNTIME} -group_reporting -iodepth_batch_submit=${param_batch} -iodepth_batch_complete_min=1 -iodepth_batch_complete_max=${param_batch} -cmd_type=nvme -fixedbufs=${param_fixedbuf} -hipri=${param_hipri} -sqthread_poll=${param_sqt} -filename=${DEV_CHAR} -output=${param_output} -name=${param_engine}_${param_iod}
	else #block-device io_uring
		fio -direct=1 -iodepth=${param_iod} -rw=$param_rw -ioengine=${param_engine} -bs=${param_bs} -numjobs=${param_jobs} -runtime=${RUNTIME} -group_reporting -iodepth_batch_submit=${param_batch} -iodepth_batch_complete_min=1 -iodepth_batch_complete_max=${param_batch} -fixedbufs=${param_fixedbuf} -hipri=${param_hipri} -sqthread_poll=${param_sqt} -filename=${DEV_BLOCK} -output=${param_output} -name=${param_engine}_${param_iod}
	fi

	echo ${label}_${param_bs}_${param_jobs}_${param_fixedbuf}_${param_hipri}_${param_iod}_${param_suffix} > col_summary.txt
	grep -nr BW $param_output | cut -d "=" -f3 | cut -d " " -f1 | cut -d "M" -f1 >> col_summary.txt
	grep -nr BW $param_output | cut -d "=" -f2 | cut -d "," -f1 >> col_summary.txt
	grep -nr avg $param_output | grep lat | grep -v clat | grep -v slat | grep -v cmlat | cut -d "=" -f4 | cut -d "," -f1 >> col_summary.txt
	grep -nr avg $param_output | grep lat | grep -v clat | grep -v slat | grep -v cmlat | cut -d "=" -f2 | cut -d "," -f1 >> col_summary.txt
	grep -nr avg $param_output | grep lat | grep -v clat | grep -v slat | grep -v cmlat | cut -d "=" -f3 | cut -d "," -f1 >> col_summary.txt

	echo $(cat col_summary.txt) >> $DIR/summary.txt
	rm col_summary.txt
}

#run_fio rw, uring_cmd, qd/iod/, iter, bs, engine, fixedbuf, hipri, sqt, batch ,jobs

#uring-passthru char-device io_uring_cmd
run_fio randread 1 1 1 4k io_uring_cmd 0 0 0 1 1
run_fio randread 1 1 1 16k io_uring_cmd 0 0 0 1 1
run_fio randread 1 1 1 64k io_uring_cmd 0 0 0 1 1

run_fio randread 1 1 1 4k io_uring_cmd 1 0 0 1 1
run_fio randread 1 1 1 16k io_uring_cmd 1 0 0 1 1
run_fio randread 1 1 1 64k io_uring_cmd 1 0 0 1 1

run_fio randread 0 1 1 4k io_uring 0 0 0 1 1
run_fio randread 0 1 1 16k io_uring 0 0 0 1 1
run_fio randread 0 1 1 64k io_uring 0 0 0 1 1

run_fio randread 0 1 1 4k io_uring 1 0 0 1 1
run_fio randread 0 1 1 16k io_uring 1 0 0 1 1
run_fio randread 0 1 1 64k io_uring 1 0 0 1 1
